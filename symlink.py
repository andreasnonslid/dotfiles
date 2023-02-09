import os
import sys
from pathlib import Path

EXCLUDE = {".git", ".DS_Store", "__pycache__", "LICENSE", "README.md", ".gitignore", ".gitmodules", ".gitattributes"}  # Add directories or files to exclude

def create_symlink(target, link_name):
    """Create or update a symlink, handling cross-platform differences."""
    try:
        # Resolve the absolute path of the target and expand '~' to the home directory
        target = os.path.abspath(os.path.expanduser(target))
        link_name = os.path.abspath(os.path.expanduser(link_name))

        # If the link already exists
        if os.path.islink(link_name):
            existing_target = os.readlink(link_name)
            if os.path.abspath(existing_target) == target:
                print(f"Symlink already exists and is correct: {link_name} -> {target}")
                return
            else:
                print(
                    f"Symlink exists but points to a different target: {link_name} -> {existing_target}, updating..."
                )
                os.unlink(link_name)  # Remove the old symlink if incorrect

        # Check if a non-symlink file or directory exists at the link path
        elif os.path.exists(link_name):
            print(
                f"Error: A file or directory already exists at {link_name}, cannot create symlink."
            )
            return

        # Create the symlink
        if os.name == "nt":  # Windows
            # Determine if target is a file or directory
            if os.path.isdir(target):
                os.symlink(target, link_name, target_is_directory=True)
            else:
                os.symlink(target, link_name)
        else:  # Unix-like
            os.symlink(target, link_name)

        print(f"Created symlink: {link_name} -> {target}")

    except Exception as e:
        print(f"Failed to create/update symlink from {target} to {link_name}: {e}")


def create_symlinks_from_directory(source_dir, dest_dir):
    """Process all files in the source directory and create symlinks"""
    # Ensure destination directory exists
    Path(dest_dir).mkdir(parents=True, exist_ok=True)

    # Iterate over all items in the source directory
    for item in os.listdir(source_dir):
        if item in EXCLUDE:
            print(f"Skipping excluded item: {item}")
            continue

        full_item_path = os.path.join(source_dir, item)
        if os.path.isfile(full_item_path) or os.path.isdir(
            full_item_path
        ):  # Check if it's a file or a directory
            link_name = os.path.join(dest_dir, item)
            create_symlink(full_item_path, link_name)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python symlink_creator.py <source_dir> <dest_dir>")
        sys.exit(1)

    source_dir = sys.argv[1]
    dest_dir = sys.argv[2]
    create_symlinks_from_directory(source_dir, dest_dir)
