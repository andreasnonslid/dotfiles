import os
import shutil
from pathlib import Path

EXCLUDE = {".git", ".DS_Store", "__pycache__", "LICENSE", "README.md", ".gitignore", ".gitmodules", ".gitattributes"}

def create_symlink(target, link_name):
    try:
        target = os.path.abspath(os.path.expanduser(target))
        link_name = os.path.abspath(os.path.expanduser(link_name))
        if os.path.islink(link_name) or os.path.exists(link_name):
            print(f"Removing existing: {link_name}")
            if os.path.isdir(link_name) and not os.path.islink(link_name):
                shutil.rmtree(link_name)
            else:
                os.unlink(link_name)
        parent_dir = os.path.dirname(link_name)
        os.makedirs(parent_dir, exist_ok=True)
        os.symlink(target, link_name)
        print(f"Created symlink: {link_name} -> {target}")
    except Exception as e:
        print(f"Failed to create symlink from {target} to {link_name}: {e}")

def symlink_dir_contents(source_dir, target_dir):
    for item in os.listdir(source_dir):
        if item in EXCLUDE:
            continue
        src_path = os.path.join(source_dir, item)
        tgt_path = os.path.join(target_dir, item)
        create_symlink(src_path, tgt_path)

def main():
    repo_root = Path(__file__).parent.resolve()
    home = Path.home()
    is_windows = os.name == "nt"

    # bashrc contents
    bashrc_source = repo_root / "bashrc"
    bashrc_target = home
    if bashrc_source.exists() and bashrc_source.is_dir():
        symlink_dir_contents(str(bashrc_source), str(bashrc_target))
    else:
        print(f"bashrc source directory not found: {bashrc_source}")

    # nvim contents
    nvim_source = repo_root / "nvim"
    if is_windows:
        nvim_target = Path(os.environ.get("LOCALAPPDATA", home / "AppData/Local")) / "nvim"
    else:
        nvim_target = home / ".config" / "nvim"

    if nvim_source.exists() and nvim_source.is_dir():
        nvim_target.mkdir(parents=True, exist_ok=True)
        symlink_dir_contents(str(nvim_source), str(nvim_target))
    else:
        print(f"nvim source directory not found: {nvim_source}")

if __name__ == "__main__":
    main()

