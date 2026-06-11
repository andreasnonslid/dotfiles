import os
import shutil
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


def create_symlink(target, link_name, auto_yes=False):
    try:
        target = os.path.abspath(os.path.expanduser(target))
        link_name = os.path.abspath(os.path.expanduser(link_name))
        parent_dir = os.path.dirname(link_name)
        # Always ensure the parent directory exists
        os.makedirs(parent_dir, exist_ok=True)
        if os.path.islink(link_name) or os.path.exists(link_name):
            if not auto_yes:
                response = input(
                    f"{link_name} exists and will be removed. Continue? [y/N]: "
                )
                if response.lower() != "y":
                    print(f"Skipped: {link_name}")
                    return
            if os.path.isdir(link_name) and not os.path.islink(link_name):
                shutil.rmtree(link_name)
            else:
                os.unlink(link_name)
            print(f"Removed existing: {link_name}")
        os.symlink(target, link_name)
        print(f"Created symlink: {link_name} -> {target}")
    except Exception as e:
        print(f"Failed to create symlink from {target} to {link_name}: {e}")


def symlink_dir_contents(source_dir, target_dir, auto_yes=False):
    for item in os.listdir(source_dir):
        if item in EXCLUDE:
            continue
        src_path = os.path.join(source_dir, item)
        tgt_path = os.path.join(target_dir, item)
        create_symlink(src_path, tgt_path, auto_yes=auto_yes)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-y", "--yes", action="store_true", help="Automatically confirm all removals"
    )
    args = parser.parse_args()

    repo_root = Path(__file__).parent.resolve()
    home = Path.home()
    is_windows = os.name == "nt"
    config_dir = home / ".config"

    # bashrc contents
    bashrc_source = repo_root / "bashrc"
    bashrc_target = home
    if bashrc_source.exists() and bashrc_source.is_dir():
        symlink_dir_contents(str(bashrc_source), str(bashrc_target), auto_yes=args.yes)
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

    if nvim_source.exists() and nvim_source.is_dir():
        symlink_dir_contents(str(nvim_source), str(nvim_target), auto_yes=args.yes)
    else:
        print(f"nvim source directory not found: {nvim_source}")

    # NOTE: fd config is not handled separately. ~/.config is itself symlinked
    # to bashrc/.config (via the bashrc loop above), so fd/ignore is already in
    # place. Re-linking it here would create a self-referential symlink.

    # NOTE: clangd and zellij configs are not handled separately either. They
    # live at bashrc/.config/{clangd,zellij}/, which is already ~/.config via
    # the symlink above, so they are the single source of truth and need no
    # extra linking. Pointing a separate source at them would self-symlink.

    # starship.toml
    starship_source = repo_root / "starship.toml"
    if is_windows:
        starship_target = (
            Path(os.environ.get("LOCALAPPDATA", home / "AppData/Local"))
            / "starship.toml"
        )
    else:
        starship_target = config_dir / "starship.toml"

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
        create_symlink(str(caveman_dir / "CLAUDE.md"), str(claude_md), auto_yes=args.yes)
    else:
        print(
            f"Skipping {claude_md}: real file exists. "
            f"Add caveman manually or '@{caveman_dir / 'CLAUDE.md'}' import."
        )

    # Local-only secrets: kept outside the repo in ~/.local/secrets and linked
    # into place only if present. These are never committed (see .gitignore).
    secrets_root = home / ".local" / "secrets"
    secret_links = {
        "autostore/gitlab-npm.env": config_dir / "autostore" / "gitlab-npm.env",
    }
    for rel_path, link_target in secret_links.items():
        secret_file = secrets_root / rel_path
        if secret_file.exists():
            create_symlink(str(secret_file), str(link_target), auto_yes=args.yes)
        else:
            print(f"Secret not found, skipping link: {secret_file}")


if __name__ == "__main__":
    main()
