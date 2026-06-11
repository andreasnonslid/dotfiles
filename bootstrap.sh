#!/usr/bin/env bash
# One-shot dotfiles setup for a fresh machine. Idempotent — safe to re-run.
#
#   git clone git@github.com:andreasnonslid/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && ./bootstrap.sh
#
# Does:
#   1. Configures git (autocrlf + commit-msg hooks) via configure_git.sh
#   2. Symlinks everything into place via symlink.py -y (bashrc, nvim, configs,
#      starship, and the always-on caveman rule for Cursor + Claude Code)
#   3. Reminds you to drop machine-local secrets into ~/.local/secrets
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Configuring git"
./configure_git.sh

echo "==> Linking dotfiles (symlink.py -y)"
if command -v python3 >/dev/null 2>&1; then
    python3 symlink.py -y
else
    echo "ERROR: python3 not found — install Python 3, then re-run." >&2
    exit 1
fi

# Secrets are never tracked. Link them in only if present (symlink.py already
# does this), otherwise tell the user what to create.
secret="$HOME/.local/secrets/autostore/gitlab-npm.env"
if [ ! -e "$secret" ]; then
    cat <<EOF

==> Optional secrets not found (skipped):
    $secret
    Create it (e.g. 'export GITLAB_ACCESS_KEY=...') then re-run ./bootstrap.sh
    to link it into ~/.config/autostore/.
EOF
fi

echo
echo "==> Done. Open a new shell. Caveman rule active in new Cursor/Claude sessions."
