#!/usr/bin/env bash
# Run once after cloning dotfiles. Run from repo root.

set -e
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

git config --global core.autocrlf input
git config core.hooksPath .githooks

echo "Git configured. Commit message hooks are active."
