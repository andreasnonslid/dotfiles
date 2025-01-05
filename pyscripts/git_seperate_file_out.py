#!/usr/bin/env python3
from git import Repo
import sys
import os

def is_subsequence(needle, haystack):
    """Return True if all chars in needle appear in haystack in order."""
    it = iter(haystack.lower())
    return all(c in it for c in needle.lower())

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file-subsequence> [base-ref] [new-branch]")
        sys.exit(1)

    needle = sys.argv[1]
    base = sys.argv[2] if len(sys.argv) > 2 else "origin/master"
    new_branch = sys.argv[3] if len(sys.argv) > 3 else f"split-{needle}"

    repo = Repo(".", search_parent_directories=True)
    commits = list(repo.iter_commits(f"{base}..HEAD", reverse=True))

    if not commits:
        print("No commits to process.")
        return

    print(f"Replaying {len(commits)} commits onto new branch '{new_branch}'...")

    # Create new branch from base
    repo.git.checkout(base, b=new_branch)

    for commit in commits:
        changed_files = commit.stats.files.keys()
        matched_files = [f for f in changed_files if is_subsequence(needle, f)]

        if not matched_files:
            print(f"Cherry-picking {commit.hexsha[:7]} (no match)")
            repo.git.cherry_pick(commit.hexsha)
            continue

        print(f"Splitting commit {commit.hexsha[:7]} -> {commit.summary}")
        print(f"  Matched files: {matched_files}")

        # First: cherry-pick into index without committing
        repo.git.cherry_pick(commit.hexsha, n=True)

        # Remove matched files from index and restore parent version or delete
        for f in matched_files:
            repo.git.reset("HEAD", f)
            try:
                repo.git.checkout(f"{commit.hexsha}^", "--", f)
            except Exception:
                repo.git.rm(f, "--ignore-unmatch")

        # Commit the rest, preserving author/date
        repo.git.commit(
            "--reuse-message", commit.hexsha,
            "--author", f"{commit.author.name} <{commit.author.email}>",
            "--date", commit.authored_datetime.isoformat()
        )

        # Now commit only the matched files from the original commit
        for f in matched_files:
            try:
                repo.git.checkout(commit.hexsha, "--", f)
            except Exception:
                continue
        repo.git.add(*matched_files)
        repo.git.commit(
            "-m", f"{commit.summary} (split: {needle})",
            "--author", f"{commit.author.name} <{commit.author.email}>",
            "--date", commit.authored_datetime.isoformat()
        )

    print(f"Done! Branch '{new_branch}' has split commits.")

if __name__ == "__main__":
    main()

