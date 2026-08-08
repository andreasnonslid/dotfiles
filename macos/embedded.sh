#!/usr/bin/env bash
# macos/embedded.sh -- ARM embedded toolchain via xpm (M25).
#
# Ports compilers/arm_gcc.sh to darwin: same xpm + fzf version-picker flow,
# same xPack install layout under ~/.local/xPacks. The only real change is
# how the selected version becomes "active" on PATH --
# `update-alternatives` doesn't exist on macOS, so this symlinks the picked
# version's binaries into ~/.local/bin instead. That directory is already
# first on PATH (see bashrc/.profile), so re-running this script and
# picking a different version is how you switch the active toolchain --
# every version stays installed side by side under ~/.local/xPacks, only
# the ~/.local/bin symlinks move.
#
# Opt-in, like the Linux compiler scripts under compilers/: not called from
# macos/install.sh or bootstrap.sh. Run it manually when you need the
# embedded toolchain.
#
#   ./macos/embedded.sh
#
# Fallback: `brew install --cask gcc-arm-embedded` also works, but is known
# to be flaky -- ARM's download server periodically blocks Homebrew's user
# agent, SHA256 mismatches happen on their end, and the cask can fail on
# case-sensitive APFS volumes. xpm is the primary path for that reason.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/os.sh
. "$root/lib/os.sh"

if ! is_macos; then
    echo "ERROR: macos/embedded.sh only runs on macOS (detected: $(detect_os))." >&2
    exit 1
fi

# Matches the current 11.3 toolchain pinned by compilers/arm11.3.sh, as an
# xPack version string. Only used to pre-select an fzf entry -- any listed
# version can still be picked.
default_version="11.3.1-1.1.2"

# Binaries shimmed into ~/.local/bin for the active version. Mirrors the
# set compilers/arm11.3.sh registers via update-alternatives, plus the g++
# entry compilers/arm_gcc.sh also manages.
embedded_bins="
arm-none-eabi-gcc
arm-none-eabi-g++
arm-none-eabi-gdb
arm-none-eabi-objcopy
arm-none-eabi-size
arm-none-eabi-objdump
arm-none-eabi-nm
"

require_tool() {
    local tool="$1" hint="$2"
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: '$tool' not found on PATH. $hint" >&2
        exit 1
    fi
}

require_tool npm "Install Node.js first (e.g. 'brew install node' -- not yet in macos/Brewfile, see M22/M23)."
require_tool xpm "Install it with: npm install --global xpm"
require_tool fzf "fzf is in macos/Brewfile -- run macos/install.sh or 'brew bundle --file macos/Brewfile'."
require_tool jq "jq is in macos/Brewfile -- run macos/install.sh or 'brew bundle --file macos/Brewfile'."

link_shims() {
    local bin_path="$1" tool shim_dir="$HOME/.local/bin"
    mkdir -p "$shim_dir"
    while IFS= read -r tool; do
        [ -z "$tool" ] && continue
        if [ -x "$bin_path/$tool" ]; then
            ln -sf "$bin_path/$tool" "$shim_dir/$tool"
        else
            echo "    WARNING: $bin_path/$tool not present in this xPack -- skipping shim." >&2
        fi
    done <<<"$embedded_bins"
    echo "    Active toolchain shimmed into $shim_dir"
}

install_version() {
    echo "==> Fetching available @xpack-dev-tools/arm-none-eabi-gcc versions via xpm"
    local versions
    versions="$(npm view @xpack-dev-tools/arm-none-eabi-gcc versions --json | jq -r '.[]')"
    if [ -z "$versions" ]; then
        echo "ERROR: no available versions found." >&2
        exit 1
    fi

    local version
    version="$(echo "$versions" | fzf --height 40% --border \
        --query "$default_version" \
        --prompt "Select arm-none-eabi-gcc version: ")"
    if [ -z "$version" ]; then
        echo "No version selected -- nothing to do."
        return
    fi

    local install_path="$HOME/.local/xPacks/@xpack-dev-tools/arm-none-eabi-gcc/$version/.content/bin"
    if [ -d "$install_path" ]; then
        echo "==> $version already installed"
    else
        echo "==> Installing arm-none-eabi-gcc@$version via xpm"
        xpm install --global "@xpack-dev-tools/arm-none-eabi-gcc@$version"
    fi

    echo "==> Activating $version"
    link_shims "$install_path"
}

install_version
