import os
import platform
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
import argparse

EXCLUDE = {
    ".git",
    ".DS_Store",
    "__pycache__",
    "LICENSE",
    "README.md",
    ".gitignore",
    ".gitmodules",
    ".gitattributes",
}

# Wayland/Linux-only entries under bashrc/.config/ that have no meaning on
# macOS.
DARWIN_CONFIG_EXCLUDE = {
    "hypr",
    "waybar",
    "mako",
    "mimeapps.list",
}

# The other direction: darwin-only entries under bashrc/.config/ that have
# no meaning on Linux/WSL. AeroSpace (M19) joins this set once it lands.
LINUX_CONFIG_EXCLUDE = {
    "ghostty",
}

# darwin only: entries generated at toolchain-install time instead of
# symlinked from the repo (M27). clangd's ARM toolchain include paths
# depend on the xpm-installed version, which isn't known until
# macos/embedded.sh actually installs one, so it renders
# ~/.config/clangd/config.yaml itself rather than this script linking the
# whole tracked directory (which holds the Linux config plus the darwin
# template, neither of which macos/embedded.sh wants as-is).
DARWIN_GENERATED_EXCLUDE = {
    "clangd",
}

# darwin only: the zsh entrypoint (M08). Linux/WSL keep bash as the login
# shell, so there is nothing to link ~/.zshrc to there.
DARWIN_ONLY_TOP_LEVEL = {
    ".zshrc",
}


# darwin: parts that only make sense on Linux/Wayland.
DARWIN_PART_EXCLUDE = {"sway", "waybar", "which-key", "fuzzel", "swaylock", "gtklock"}
# The other direction: parts that only make sense on macOS.
LINUX_PART_EXCLUDE = {"aerospace", "hammerspoon"}


# Only link what the machine can use: an entry is skipped when none of its tools is installed.
# Each value is "any of": a command name (looked up on PATH plus the usual extra dirs) or an
# absolute path (macOS apps). Entries not listed here (palette, git, ...) are always linked.
PART_NEEDS = {
    "sway": ["sway"],
    "waybar": ["waybar"],
    "which-key": ["wlr-which-key"],
    "fuzzel": ["fuzzel"],
    "swaylock": ["swaylock"],
    "gtklock": ["gtklock"],
    "alacritty": ["alacritty", "/Applications/Alacritty.app"],
    "aerospace": ["aerospace", "/Applications/AeroSpace.app"],
    "hammerspoon": ["hs", "/Applications/Hammerspoon.app"],
}
CONFIG_NEEDS = {  # entries of bashrc/.config
    "ghostty": ["ghostty", "/Applications/Ghostty.app"],
    "hypr": ["Hyprland", "hyprland"],
    "waybar": ["waybar"],
    "mako": ["mako"],
    "zed": ["zed", "/Applications/Zed.app"],
    "zellij": ["zellij"],
    "mise": ["mise"],
    "gh": ["gh"],
    "fd": ["fd", "fdfind"],
    "clangd": ["clangd"],
}
EXTRA_BIN_DIRS = ("~/.cargo/bin", "~/.local/bin", "/opt/homebrew/bin", "/usr/local/bin")


def tool_present(spec):
    """True if `spec` (command name or absolute path) exists on this machine."""
    if spec.startswith("/"):
        return os.path.exists(spec)
    path = os.pathsep.join(
        [os.environ.get("PATH", "")] + [os.path.expanduser(d) for d in EXTRA_BIN_DIRS]
    )
    return shutil.which(spec, path=path) is not None


def installed(needs):
    return any(tool_present(spec) for spec in needs)


def create_symlink(target, link_name, auto_yes=False):
    try:
        target = os.path.abspath(os.path.expanduser(target))
        link_name = os.path.abspath(os.path.expanduser(link_name))
        parent_dir = os.path.dirname(link_name)
        # Always ensure the parent directory exists
        os.makedirs(parent_dir, exist_ok=True)
        # If the parent is itself a symlink into the target's tree (an older installer linked ~/.config wholesale into the repo),
        # link_name already IS the target. Moving it aside and linking it to itself would back up the repo's own folder and
        # leave a symlink that points at itself.
        if os.path.join(
            os.path.realpath(parent_dir), os.path.basename(link_name)
        ) == os.path.realpath(target):
            print(f"Already in place, left alone: {link_name}")
            return
        if os.path.islink(link_name) or os.path.exists(link_name):
            if not auto_yes:
                response = input(
                    f"{link_name} exists and will be removed. Continue? [y/N]: "
                )
                if response.lower() != "y":
                    print(f"Skipped: {link_name}")
                    return
            if os.path.islink(link_name):
                os.unlink(link_name)
                print(f"Removed existing symlink: {link_name}")
            else:
                backup = f"{link_name}.bak-{datetime.now():%Y%m%d%H%M%S}"
                shutil.move(link_name, backup)
                print(f"Backed up existing {link_name} -> {backup}")
        os.symlink(target, link_name)
        print(f"Created symlink: {link_name} -> {target}")
    except Exception as e:
        print(f"Failed to create symlink from {target} to {link_name}: {e}")


def repair_wholesale_config(config_dir, repo_root, auto_yes=False, dry_run=False):
    """Older installers linked ~/.config wholesale to <repo>/bashrc/.config, so every app wrote its state into the repo. Make
    ~/.config a real directory: what git does not track (app state, links made by part linking) moves into it; tracked entries stay
    in the repo and are linked into it by the normal install afterwards. Nothing is deleted. Returns True when it repaired,
    False when there was nothing to do or it was not safe to (not a link into this repo, no git to tell tracked from untracked,
    or the question was answered no); with dry_run, the names that would move."""
    config_dir, repo_root = Path(config_dir), Path(repo_root).resolve()
    if not config_dir.is_symlink():
        return False
    real = Path(os.path.realpath(config_dir))
    if repo_root not in real.parents:
        return False
    try:
        listed = subprocess.run(
            [
                "git",
                "-C",
                str(repo_root),
                "ls-files",
                "-z",
                "--",
                str(real.relative_to(repo_root)),
            ],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        print(
            f"WARNING: cannot ask git what is tracked in {real}; leaving ~/.config alone"
        )
        return False
    rel = real.relative_to(repo_root)
    tracked = {Path(f).relative_to(rel).parts[0] for f in listed.split("\0") if f}
    move = sorted(n for n in os.listdir(real) if n not in tracked and n not in EXCLUDE)
    if dry_run:
        return move
    print(
        f"~/.config is a symlink into the repo ({real}). Making it a real directory; moving the untracked entries into it: {', '.join(move) or 'none'}"
    )
    if not auto_yes and input("Continue? [y/N]: ").lower() != "y":
        print("Skipped: ~/.config repair")
        return False
    fresh = config_dir.with_name(f".config.new-{datetime.now():%Y%m%d%H%M%S}")
    fresh.mkdir()
    for name in move:
        shutil.move(str(real / name), str(fresh / name))
        print(f"Moved {real / name} -> {config_dir / name}")
    config_dir.unlink()  # the link only; the repo's folder stays where it is
    fresh.rename(config_dir)
    return True


def keep_ssh_config(ssh_config, secrets_root):
    """A real ~/.ssh/config is about to be replaced by the tracked one, which Includes ~/.local/secrets/ssh/*.conf for host entries.
    Keep the old file there (once; never over a file that is already there) so its hosts keep working.
    """
    if ssh_config.is_symlink() or not ssh_config.is_file():
        return
    kept = secrets_root / "ssh" / "legacy-config.conf"
    if kept.exists():
        return
    kept.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ssh_config, kept)
    os.chmod(kept, 0o600)
    print(f"Kept the old ssh config as {kept} (it is Included by the tracked config)")


def symlink_dir_contents(source_dir, target_dir, auto_yes=False, extra_exclude=None):
    exclude = EXCLUDE | (extra_exclude or set())
    for item in os.listdir(source_dir):
        if item in exclude:
            continue
        src_path = os.path.join(source_dir, item)
        tgt_path = os.path.join(target_dir, item)
        create_symlink(src_path, tgt_path, auto_yes=auto_yes)


def part_links(part_dir, home):
    """(src, dst) pairs for one part: a dir that mirrors $HOME, with the
    entries of its .config/ linked into ~/.config one by one (never wholesale)."""
    for item in sorted(os.listdir(part_dir)):
        if item in EXCLUDE:
            continue
        src = Path(part_dir) / item
        if item == ".config" and src.is_dir():
            if (home / ".config").is_symlink():
                print(
                    f"Skipped {src}: ~/.config is a symlink, so linking into it would write into its target"
                )
                continue
            for sub in sorted(os.listdir(src)):
                yield src / sub, home / ".config" / sub
        else:
            yield src, home / item


def link_part(part_dir, home, auto_yes=True):
    for src, dst in part_links(part_dir, home):
        create_symlink(str(src), str(dst), auto_yes=auto_yes)


def unlink_part(part_dir, home):
    """Remove only links that point into the part; leave anything else alone."""
    part_dir = Path(part_dir).resolve()
    for _, dst in part_links(part_dir, home):
        if dst.is_symlink() and Path(os.path.realpath(dst)).is_relative_to(part_dir):
            dst.unlink()
            print(f"Unlinked: {dst}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--link", nargs="+", metavar="PART", help="link only these parts/ and exit"
    )
    parser.add_argument(
        "--unlink", nargs="+", metavar="PART", help="unlink these parts/ and exit"
    )
    parser.add_argument(
        "-y", "--yes", action="store_true", help="Automatically confirm all removals"
    )
    args = parser.parse_args()

    repo_root = Path(__file__).parent.resolve()
    home = Path.home()
    is_windows = os.name == "nt"
    is_darwin = platform.system() == "Darwin"
    config_dir = home / ".config"
    parts_dir = repo_root / "parts"
    # An older installer linked ~/.config wholesale (into this repo). Writing "into" it writes into wherever it points, so nothing
    # below touches ~/.config on such a machine; the fix is to make ~/.config a real directory.
    if not is_windows and not (args.link or args.unlink):
        repair_wholesale_config(config_dir, repo_root, auto_yes=args.yes)
    config_is_link = config_dir.is_symlink()
    if config_is_link and not (args.link or args.unlink):
        print(
            f"WARNING: ~/.config is a symlink to {os.path.realpath(config_dir)}. Anything linked or written into it would write straight into "
            "that folder (and so into git when it is this repo). Skipping every ~/.config link; make ~/.config a real directory to fix this."
        )

    # Part management: `--unlink old --link new` swaps one part for another.
    if args.link or args.unlink:
        for name in args.unlink or []:
            unlink_part(parts_dir / name, home)
        for name in args.link or []:
            link_part(parts_dir / name, home)
        return

    # bashrc contents (dotfiles that land directly in $HOME, e.g. .bashrc)
    bashrc_source = repo_root / "bashrc"
    if bashrc_source.exists() and bashrc_source.is_dir():
        for item in os.listdir(bashrc_source):
            if item in EXCLUDE:
                continue
            if item in DARWIN_ONLY_TOP_LEVEL and not is_darwin:
                continue
            src_path = bashrc_source / item
            if item == ".config" and config_is_link:
                continue
            if item == ".config":
                # Never symlink ~/.config wholesale: every app that writes
                # into $XDG_CONFIG_HOME (browsers, 1Password, ...) would end
                # up writing straight into this git repo. Keep ~/.config a
                # real directory and link only the tracked configs into it.
                config_dir.mkdir(parents=True, exist_ok=True)
                config_exclude = (
                    DARWIN_CONFIG_EXCLUDE | DARWIN_GENERATED_EXCLUDE
                    if is_darwin
                    else LINUX_CONFIG_EXCLUDE
                )
                missing = {
                    n for n, needs in CONFIG_NEEDS.items() if not installed(needs)
                }
                for n in sorted(missing - config_exclude):
                    print(f"Skipped (not installed): ~/.config/{n}")
                symlink_dir_contents(
                    str(src_path),
                    str(config_dir),
                    auto_yes=args.yes,
                    extra_exclude=config_exclude | missing,
                )
            elif item == ".ssh":
                # Never symlink ~/.ssh wholesale: private keys, known_hosts
                # and agent state must never live inside the git repo. Same
                # carve-out as ~/.config above -- link only the tracked
                # config file(s) in. config.darwin (M30's macOS-only
                # UseKeychain block) is linked in only on darwin; the base
                # config's Include silently skips it otherwise.
                ssh_dir = home / ".ssh"
                ssh_dir.mkdir(parents=True, exist_ok=True)
                os.chmod(ssh_dir, 0o700)
                keep_ssh_config(ssh_dir / "config", home / ".local" / "secrets")
                ssh_exclude = set() if is_darwin else {"config.darwin"}
                symlink_dir_contents(
                    str(src_path),
                    str(ssh_dir),
                    auto_yes=args.yes,
                    extra_exclude=ssh_exclude,
                )
            else:
                create_symlink(str(src_path), str(home / item), auto_yes=args.yes)
    else:
        print(f"bashrc source directory not found: {bashrc_source}")

    # nvim contents
    nvim_source = repo_root / "nvim"
    if is_windows:
        nvim_target = (
            Path(os.environ.get("LOCALAPPDATA", home / "AppData/Local")) / "nvim"
        )
    else:
        nvim_target = config_dir / "nvim"

    if config_is_link and not is_windows:
        pass  # see the warning above
    elif nvim_source.exists() and nvim_source.is_dir():
        symlink_dir_contents(str(nvim_source), str(nvim_target), auto_yes=args.yes)
    else:
        print(f"nvim source directory not found: {nvim_source}")

    # fd, clangd, zellij configs live at bashrc/.config/{fd,clangd,zellij}/
    # and are linked individually into ~/.config by the bashrc loop above.

    # starship.toml
    starship_source = repo_root / "starship.toml"
    if is_windows:
        starship_target = (
            Path(os.environ.get("LOCALAPPDATA", home / "AppData/Local"))
            / "starship.toml"
        )
    else:
        starship_target = config_dir / "starship.toml"

    if not (config_is_link and not is_windows):
        create_symlink(str(starship_source), str(starship_target), auto_yes=args.yes)

    # caveman: always-on terse-output rule for Cursor (IDE + CLI) and Claude Code
    caveman_dir = repo_root / "caveman"
    # Cursor reads file-backed global rules from ~/.cursor/rules/*.mdc
    create_symlink(
        str(caveman_dir / "caveman.mdc"),
        str(home / ".cursor" / "rules" / "caveman.mdc"),
        auto_yes=args.yes,
    )
    # Claude Code global memory lives at ~/.claude/CLAUDE.md. Only link it when
    # nothing real would be clobbered (don't overwrite existing user memory).
    claude_md = home / ".claude" / "CLAUDE.md"
    if claude_md.is_symlink() or not claude_md.exists():
        create_symlink(
            str(caveman_dir / "CLAUDE.md"), str(claude_md), auto_yes=args.yes
        )
    else:
        print(
            f"Skipping {claude_md}: real file exists. "
            f"Add caveman manually or '@{caveman_dir / 'CLAUDE.md'}' import."
        )

    # Claude Code skills: each claude/skills/<name>/ links to ~/.claude/skills/<name>
    # (same path on every OS; ~/.claude/skills/synced is Claude's own and untouched).
    skills_dir = repo_root / "claude" / "skills"
    if skills_dir.is_dir():
        for skill in sorted(skills_dir.iterdir()):
            if skill.is_dir():
                create_symlink(
                    str(skill),
                    str(home / ".claude" / "skills" / skill.name),
                    auto_yes=args.yes,
                )

    # parts/<name>/: swappable pieces (terminal, WM, bar, ...), see part_links.
    # Windows gets none: they are Linux/macOS desktop configs (Hyper also collides with the
    # Office key shortcuts there), so linking them would only leave dead files in the profile.
    if parts_dir.is_dir() and not is_windows:
        for part in sorted(parts_dir.iterdir()):
            skip = DARWIN_PART_EXCLUDE if is_darwin else LINUX_PART_EXCLUDE
            if not part.is_dir() or part.name in skip:
                continue
            if part.name in PART_NEEDS and not installed(PART_NEEDS[part.name]):
                print(f"Skipped (not installed): parts/{part.name}")
                continue
            link_part(part, home, auto_yes=args.yes)

    # Local-only secrets: kept outside the repo in ~/.local/secrets and linked
    # into place only if present. These are never committed (see .gitignore).
    secrets_root = home / ".local" / "secrets"
    secret_links = {
        "autostore/gitlab-npm.env": config_dir / "autostore" / "gitlab-npm.env",
    }
    for rel_path, link_target in secret_links.items():
        secret_file = secrets_root / rel_path
        if config_is_link and not is_windows and link_target.is_relative_to(config_dir):
            print(f"Skipped (~/.config is a symlink): {link_target}")
        elif secret_file.exists():
            create_symlink(str(secret_file), str(link_target), auto_yes=args.yes)
        else:
            print(f"Secret not found, skipping link: {secret_file}")


if __name__ == "__main__":
    main()
