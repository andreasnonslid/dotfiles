"""Theme generator. Two independent choices, mix and match:
  colors  parts/palette/.config/palette/colors/NAME.toml   (what it looks like)
  style   parts/palette/.config/palette/styles/NAME.toml   (shape: gaps, radius, bar, wallpaper)

  theme.py list colors|styles | current
  theme.py colors NAME | style NAME | apply [COLORS [STYLE]] | next-colors | next-style | random

Everything is generated from the two choices (committed, so symlinks just work):
  sway, waybar, alacritty, fuzzel, which-key, swaylock, mako, hammerspoon (parts/)
  starship.toml, zellij (themes/dotfiles.kdl + managed lines in config.kdl),
  nvim/colors/palette.lua, palette/env.sh (fzf, bat; sourced by tools/palette.sh)
Not committed (per machine): GTK3/4 gtk.css in ~/.config, wallpaper in ~/.local/share/palette.
"""
from pathlib import Path
import os
import random
import subprocess
import sys
from .core import PALETTE, PARTS, WALLPAPER, current, load, names, sh
from .render_terminal import zellij_options
from .system import gdm_input, gsettings, make_cursors, make_icons
from .visuals import make_plymouth, make_splash_bg, wallpaper
from .renderers import RENDERERS


def apply(colors, style, reload=True):
    c, s = load("colors", colors), load("styles", style)
    for r in RENDERERS:
        for rel, text in r(c, s).items():
            dst = Path(rel) if os.path.isabs(rel) else (PARTS / rel).resolve()
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text(text)
    zellij_options(s)
    (PALETTE / "current-colors").write_text(colors + "\n")
    (PALETTE / "current-styles").write_text(style + "\n")
    wallpaper(c, s["wallpaper"])
    make_cursors(c)
    try:
        make_splash_bg(c)
        subprocess.run(["python3", str(PARTS / "sway/.config/sway/quote-frame.py"), "--render",
                        str(WALLPAPER.parent / "lock-frame.png")], check=False,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        make_plymouth(c)
    except Exception as e:  # cairo/pango missing: the splash just isn't regenerated
        print(f"plymouth theme skipped: {e}", file=sys.stderr)
    icons = make_icons(c)
    gdm_input(c)
    if reload:
        gsettings(c, icons)
    if reload:
        sh("swaymsg", "reload")
        sh("pkill", "-SIGUSR2", "-x", "waybar")
        sh("makoctl", "reload")
    print(f"colors: {colors}  style: {style}")


def cycle(kind):
    ns = names(kind)
    return ns[(ns.index(current(kind)) + 1) % len(ns)]


def main(argv):
    cmd, args = (argv[1] if len(argv) > 1 else "current"), argv[2:]
    cc, cs = current("colors"), current("styles")
    if cmd == "list" and args[:1] in (["colors"], ["styles"]):
        print("\n".join(names(args[0])))
    elif cmd == "current":
        print(f"colors: {cc}  style: {cs}")
    elif cmd == "colors" and args:
        apply(args[0], cs)
    elif cmd == "style" and args:
        apply(cc, args[0])
    elif cmd == "apply" and args:
        apply(args[0], args[1] if len(args) > 1 else cs)
    elif cmd == "next-colors":
        apply(cycle("colors"), cs)
    elif cmd == "next-style":
        apply(cc, cycle("styles"))
    elif cmd == "random":
        apply(random.choice(names("colors")), random.choice(names("styles")))
    else:
        sys.exit(__doc__)
