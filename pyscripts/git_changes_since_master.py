#!/usr/bin/env python3
import argparse
import subprocess
import sys

def run_git(args):
    try:
        return subprocess.check_output(["git"] + args, text=True)
    except subprocess.CalledProcessError as e:
        sys.stderr.write(e.output)
        sys.exit(e.returncode or 1)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("needle", help="Substring to search for in changed file paths")
    ap.add_argument("--base", default="origin/master", help="Base ref (default: origin/master)")
    ap.add_argument("--head", default="HEAD", help="Head ref (default: HEAD)")
    ap.add_argument("--symmetric", action="store_true", help="Use BASE...HEAD instead of BASE..HEAD")
    args = ap.parse_args()

    commit_range = f"{args.base}...{args.head}" if args.symmetric else f"{args.base}..{args.head}"
    output = run_git(["log", commit_range, "--name-status", "--pretty=%H%x1f%s"])

    current_hash = None
    current_msg = None
    printed = set()

    for line in output.splitlines():
        if "\x1f" in line:  # commit header
            current_hash, current_msg = line.split("\x1f", 1)
        elif line.strip():  # file change line
            parts = line.split("\t", 1)
            if len(parts) > 1:
                path = parts[1]
                if args.needle in path and current_hash not in printed:
                    print(f"{current_hash} {current_msg}")
                    printed.add(current_hash)

if __name__ == "__main__":
    main()

