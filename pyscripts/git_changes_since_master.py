#!/usr/bin/env python3
from git import Repo
import sys

needle = sys.argv[1] if len(sys.argv) > 1 else input("Search letters: ")
base = "origin/master"

def is_subsequence(needle, haystack):
    it = iter(haystack.lower())
    return all(c in it for c in needle.lower())

repo = Repo(".", search_parent_directories=True)
commits = list(repo.iter_commits(f"{base}..HEAD", reverse=True))

matches = []
for commit in commits:
    for f in commit.stats.files.keys():
        if is_subsequence(needle, f):
            matches.append((commit.hexsha, commit.summary, f))

if not matches:
    print(f"No commits found containing subsequence '{needle}'.")
    sys.exit(0)

seen = set()
for sha, msg, path in matches:
    if sha not in seen:
        print(f"{sha[:7]} {msg}  [{path}]")
        seen.add(sha)

