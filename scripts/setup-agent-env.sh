#!/usr/bin/env bash
# Installs the toolchain agents (and check.sh) need to verify this repo —
# shfmt, stylua, taplo, lua, zsh, and shellcheck itself. Skips anything
# already on PATH, so re-running is fast. Also confirms core.hooksPath is
# set, since .githooks/pre-commit and commit-msg silently never run without
# it.
#
# Safe to run by hand on any Debian/Ubuntu box:
#   ./scripts/setup-agent-env.sh
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
fi

# apt-installable tools: package name paired with the binary it provides.
apt_missing=()
for pkg_bin in shellcheck:shellcheck shfmt:shfmt zsh:zsh lua5.4:lua python3-pytest:pytest; do
    pkg="${pkg_bin%%:*}"
    bin="${pkg_bin##*:}"
    command -v "$bin" >/dev/null 2>&1 || apt_missing+=("$pkg")
done

if [ "${#apt_missing[@]}" -gt 0 ]; then
    echo "==> apt: installing ${apt_missing[*]}"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y --no-install-recommends "${apt_missing[@]}"
else
    echo "==> apt: shellcheck, shfmt, zsh, lua, pytest already present"
fi

# stylua and taplo have no apt package; the *-bin npm packages ship the
# prebuilt binary and are far faster than a cargo build from source.
npm_missing=()
command -v stylua >/dev/null 2>&1 || npm_missing+=("@johnnymorganz/stylua-bin")
command -v taplo >/dev/null 2>&1 || npm_missing+=("@taplo/cli")

if [ "${#npm_missing[@]}" -gt 0 ]; then
    if ! command -v npm >/dev/null 2>&1; then
        echo "ERROR: npm not found — required to install: ${npm_missing[*]}" >&2
        exit 1
    fi
    echo "==> npm: installing ${npm_missing[*]}"
    npm install -g "${npm_missing[@]}"
else
    echo "==> npm: stylua, taplo already present"
fi

# Neovim: nvim/tests/run.sh needs 0.11+, which is newer than the apt package on
# every distro this repo targets, so it comes from the release tarball -- the
# same source linux/ubuntu.sh uses and the same path bashrc/.bashrc prepends.
nvim_prefix="$HOME/.local/opt/nvim-linux-x86_64"
if ! command -v nvim >/dev/null 2>&1; then
    echo "==> neovim: installing release tarball to $nvim_prefix"
    mkdir -p "$(dirname "$nvim_prefix")"
    tmp_tarball="$(mktemp -d)/nvim.tar.gz"
    curl -fsSL -o "$tmp_tarball" \
        https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
    tar -xzf "$tmp_tarball" -C "$(dirname "$nvim_prefix")"
    rm -rf "$(dirname "$tmp_tarball")"
    export PATH="$nvim_prefix/bin:$PATH"
    # Exporting PATH only reaches this script. Agents run each command in a
    # fresh shell that never sources .bashrc, so without a link on the default
    # PATH check.sh reports "missing nvim" on a machine that just installed it
    # -- the exact silent-red failure this stage exists to avoid. Interactive
    # shells still prefer the .bashrc-prepended copy, which is this same binary.
    if [ -w /usr/local/bin ] || [ -n "$SUDO" ]; then
        $SUDO ln -sf "$nvim_prefix/bin/nvim" /usr/local/bin/nvim
    fi
else
    echo "==> neovim: already present ($(nvim --version | head -1))"
fi

# lua gets its own hard check: .githooks/pre-commit fails closed without it,
# blocking every commit with a misleading "Files need formatting" message.
echo "==> Verifying lua"
if ! command -v lua >/dev/null 2>&1; then
    echo "ERROR: lua still not on PATH after installing lua5.4." >&2
    echo "       Check 'update-alternatives --list lua-interpreter'." >&2
    exit 1
fi
lua -v

echo "==> Configuring git hooks path"
current_hooks_path="$(git config --get core.hooksPath || true)"
if [ "$current_hooks_path" != ".githooks" ]; then
    git config core.hooksPath .githooks
    echo "    core.hooksPath was '${current_hooks_path:-<unset>}', set to .githooks"
else
    echo "    core.hooksPath already .githooks"
fi

echo
echo "==> Done. shellcheck, shfmt, stylua, taplo, lua, zsh, nvim ready."
