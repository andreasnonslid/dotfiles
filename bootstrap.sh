#!/usr/bin/env bash
# One-shot dotfiles setup for a fresh machine. Idempotent — safe to re-run.
#
#   git clone git@github.com:andreasnonslid/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && ./bootstrap.sh
#
# Does:
#   1. Configures git (autocrlf + commit-msg hooks) via configure_git.sh
#   2. On macOS: runs macos/install.sh (Homebrew, casks, defaults) first.
#      On Linux (incl. WSL): no package install here -- see linux/<distro>.sh.
#   3. Symlinks everything into place via symlink.py -y (bashrc, nvim, configs,
#      starship, and the always-on caveman rule for Cursor + Claude Code)
#   4. Reminds you to drop machine-local secrets into ~/.local/secrets
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/os.sh
. lib/os.sh

echo "==> Configuring git"
./configure_git.sh

os="$(detect_os)"
case "$os" in
darwin)
    if [ -x macos/install.sh ]; then
        echo "==> Running macOS provisioning (macos/install.sh)"
        ./macos/install.sh
    else
        cat >&2 <<EOF
ERROR: macos/install.sh not found or not executable.
       macOS provisioning has not landed in this repo yet.
EOF
        exit 1
    fi
    ;;
linux)
    # Current behaviour preserved: package installation stays a separate,
    # manual step (linux/<distro>.sh) -- bootstrap.sh only symlinks.
    ;;
*)
    cat >&2 <<EOF
ERROR: unsupported OS '$os' (uname -s: $(uname -s)).
       bootstrap.sh supports macOS and Linux (including WSL).
       For native Windows, see windows/initial_install.ps1 instead.
EOF
    exit 1
    ;;
esac

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
