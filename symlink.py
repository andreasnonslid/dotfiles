import os
import sys
from pathlib import Path

EXCLUDE = {".git", ".DS_Store", "__pycache__", "LICENSE", "README.md", ".gitignore", ".gitmodules", ".gitattributes"}

def create_symlink(target, link_name):
    try:
        target = os.path.abspath(os.path.expanduser(target))
        link_name = os.path.abspath(os.path.expanduser(link_name))
        if os.path.islink(link_name):
            existing_target = os.readlink(link_name)
            if os.path.abspath(existing_target) == target:
                print(f"Symlink already exists and is correct: {link_name} -> {target}")
                return
            else:
                print(f"Symlink exists but points to a different target: {link_name} -> {existing_target}, updating...")
                os.unlink(link_name)
        elif os.path.exists(link_name):
            print(f"Error: A file or directory already exists at {link_name}, cannot create symlink.")
            return
        if os.name == "nt":
            if os.path.isdir(target):
                os.symlink(target, link_name, target_is_directory=True)
            else:
                os.symlink(target, link_name)
        else:
            os.symlink(target, link_name)
        print(f"Created symlink: {link_name} -> {target}")
    except Exception as e:
        print(f"Failed to create/update symlink from {target} to {link_name}: {e}")

def main():
    repo_root = Path(__file__).parent.resolve()
    home = Path.home()
    is_windows = os.name == "nt"

    # bashrc
    bashrc_source = repo_root / "bashrc"
    bashrc_target = home / "bashrc"
    if bashrc_source.exists():
        create_symlink(str(bashrc_source), str(bashrc_target))
    else:
        print(f"bashrc source not found: {bashrc_source}")

    # nvim
    nvim_source = repo_root / "nvim"
    if is_windows:
        nvim_target = Path(os.environ.get("LOCALAPPDATA", home / "AppData/Local")) / "nvim"
    else:
        nvim_target = home / ".config" / "nvim"
    if nvim_source.exists():
        nvim_target.parent.mkdir(parents=True, exist_ok=True)
        create_symlink(str(nvim_source), str(nvim_target))
    else:
        print(f"nvim source not found: {nvim_source}")

if __name__ == "__main__":
    main()
