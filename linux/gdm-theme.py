#!/usr/bin/env python3
"""Root helper: theme the GDM login screen from the user's palette.

Installed root-owned at /usr/local/libexec/dotfiles-gdm-theme and run by the
dotfiles-gdm-theme.path/.service units when ~USER/.local/share/palette/gdm-input.json
changes (written by scripts/theme.py). Usage: dotfiles-gdm-theme USER

Runs as root on user-writable input, so it only accepts: #rrggbb colors, one
known accent name, a plain PNG file, and theme dirs copied with symlinks=True.
Nothing from the input is executed or interpolated unchecked.
"""

import json
import os
import pwd
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RES = Path("/usr/share/gnome-shell/gnome-shell-theme.gresource")
ORIG = RES.with_name(RES.name + ".orig-dotfiles")
PREFIX = "/org/gnome/shell/theme/"
WALL = Path("/usr/share/gdm/palette-wallpaper.png")
MARK = ("# BEGIN dotfiles theme", "# END dotfiles theme")
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
ACCENTS = {
    "blue",
    "teal",
    "green",
    "yellow",
    "orange",
    "red",
    "pink",
    "purple",
    "slate",
}
KEYS = ("bg", "fg", "dim", "accent")


def mix(a, b, t):
    ca, cb = (tuple(int(x[i : i + 2], 16) for i in (1, 3, 5)) for x in (a, b))
    return "#%02x%02x%02x" % tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))


def main():
    if os.geteuid() != 0 or len(sys.argv) != 2:
        sys.exit("usage (root): dotfiles-gdm-theme USER")
    home = Path(pwd.getpwnam(sys.argv[1]).pw_dir)
    pal = home / ".local/share/palette"
    data = json.loads((pal / "gdm-input.json").read_text())
    c = {k: data["colors"][k] for k in KEYS}
    assert all(HEX.match(v) for v in c.values()), "bad color"
    accent_name = data["accent"] if data["accent"] in ACCENTS else "blue"

    wp = (
        pal / "splash-bg.png"
    )  # the horizon art; the quote is added only by sway/the splash
    assert (
        wp.is_file() and not wp.is_symlink() and wp.stat().st_size < 16_000_000
    ), "bad wallpaper"
    with wp.open("rb") as f:
        assert f.read(8) == b"\x89PNG\r\n\x1a\n", "wallpaper is not a PNG"
    shutil.copyfile(wp, WALL)
    os.chmod(WALL, 0o644)

    icons = home / ".local/share/icons"
    for n in ("dotfiles", "dotfiles-icons"):
        d = icons / n
        if d.is_dir() and not d.is_symlink():
            shutil.rmtree(f"/usr/share/icons/{n}", ignore_errors=True)
            shutil.copytree(d, f"/usr/share/icons/{n}", symlinks=True)
    has_icons = Path("/usr/share/icons/dotfiles-icons").is_dir()

    if not ORIG.exists():
        shutil.copy2(RES, ORIG)
    tmp = Path(tempfile.mkdtemp())
    names = subprocess.run(
        ["gresource", "list", str(ORIG)], capture_output=True, text=True, check=True
    ).stdout.split()
    for r in names:
        out = tmp / r[len(PREFIX) :]
        out.write_bytes(
            subprocess.run(
                ["gresource", "extract", str(ORIG), r], capture_output=True, check=True
            ).stdout
        )
    css = (tmp / "gnome-shell-dark.css").read_text()
    bg, fg = c["bg"], c["fg"]
    # The shell's CSS only takes lengths for background-size (not "cover"), so use the panel's size.
    w, h = 1920, 1080
    for modes in sorted(Path("/sys/class/drm").glob("card*-*/modes")):
        try:
            if (modes.parent / "status").read_text().strip() == "connected":
                w, h = map(int, modes.read_text().split()[0].split("x"))
                break
        except (OSError, ValueError):
            pass
    for old, new in {
        "#222226": bg,
        "#2e2e33": mix(bg, fg, 0.05),
        "#36363a": mix(bg, fg, 0.10),
        "#38383b": mix(bg, fg, 0.11),
        "#424247": mix(bg, fg, 0.14),
        "#47474c": mix(bg, fg, 0.16),
        "#4a4a4f": mix(bg, fg, 0.17),
        "#4d4d4d": mix(bg, fg, 0.18),
        "#56565c": mix(bg, fg, 0.22),
        "#9b9b9d": c["dim"],
        "#fafafb": fg,
        "#ffffff": fg,
    }.items():
        css = css.replace(old, new)
    css, n = re.subn(
        r"#lockDialogGroup \{[^}]*\}",
        "#lockDialogGroup {\n  background-color: %s;\n"
        "  background-image: url(file:///usr/share/gdm/palette-wallpaper.png);\n"
        "  background-size: %dpx %dpx; background-position: 0px 0px; background-repeat: no-repeat; }"
        % (bg, w, h),
        css,
        count=1,
    )
    assert n == 1, "lockDialogGroup not found; shell theme changed"
    (tmp / "gnome-shell-dark.css").write_text(css)
    xml = '<?xml version="1.0" encoding="UTF-8"?>\n<gresources><gresource prefix="/org/gnome/shell/theme">\n'
    xml += (
        "".join(f"  <file>{r[len(PREFIX):]}</file>\n" for r in names)
        + "</gresource></gresources>\n"
    )
    (tmp / "theme.gresource.xml").write_text(xml)
    new = tmp / "out.gresource"
    subprocess.run(
        [
            "glib-compile-resources",
            f"--sourcedir={tmp}",
            f"--target={new}",
            str(tmp / "theme.gresource.xml"),
        ],
        check=True,
    )
    got = subprocess.run(
        ["gresource", "list", str(new)], capture_output=True, text=True, check=True
    ).stdout.split()
    assert sorted(got) == sorted(names), "resource list mismatch"
    os.chmod(new, 0o644)
    shutil.move(str(new), str(RES))
    shutil.rmtree(tmp)

    gp = Path("/etc/gdm3/greeter.dconf-defaults")
    txt = re.sub(
        rf"\n?{re.escape(MARK[0])}.*?{re.escape(MARK[1])}\n?",
        "\n",
        gp.read_text(),
        flags=re.S,
    )
    block = (
        f"{MARK[0]}\n[org/gnome/desktop/interface]\ncolor-scheme='prefer-dark'\n"
        f"accent-color='{accent_name}'\ncursor-theme='dotfiles'\n"
        + ("icon-theme='dotfiles-icons'\n" if has_icons else "")
        + f"{MARK[1]}\n"
    )
    gp.write_text(txt.rstrip("\n") + "\n\n" + block)
    subprocess.run(["/usr/share/gdm/generate-config"], check=False)


if __name__ == "__main__":
    main()
