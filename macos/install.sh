#!/usr/bin/env bash
# macos/install.sh -- macOS provisioning orchestrator (M13).
#
# Installs Xcode Command Line Tools, installs Homebrew, wires the Homebrew
# shellenv so this script's own `brew` calls resolve, runs `brew bundle`
# against macos/Brewfile, then runs macos/defaults.sh. Idempotent -- each
# step checks first and is a no-op once satisfied, so re-running is fast.
#
# Called from bootstrap.sh on darwin; not meant to be run on any other OS.
# macos/Brewfile (M14) and macos/defaults.sh (M16) haven't landed yet, so
# those two steps skip loudly with a pointer to the item that adds them.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/os.sh
. "$root/lib/os.sh"

if ! is_macos; then
    echo "ERROR: macos/install.sh only runs on macOS (detected: $(detect_os))." >&2
    exit 1
fi

echo "==> Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
    echo "    already installed"
else
    echo "    installing -- this pops a GUI installer, waiting for it to finish"
    xcode-select --install
    until xcode-select -p >/dev/null 2>&1; do
        sleep 5
    done
    echo "    installed"
fi

echo "==> Homebrew"
arch="$(detect_arch)"
case "$arch" in
arm64) brew_prefix=/opt/homebrew ;;
*) brew_prefix=/usr/local ;;
esac

if [ -x "$brew_prefix/bin/brew" ]; then
    echo "    already installed at $brew_prefix"
else
    echo "    installing to $brew_prefix (NONINTERACTIVE=1)"
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Wires brew onto PATH for the rest of this script. Persisting it into an
# interactive shell's rc file is out of scope here -- that belongs with the
# zsh adapter (M06/M08), not the provisioning orchestrator.
eval "$("$brew_prefix/bin/brew" shellenv)"

echo "==> brew bundle"
if [ -f "$root/macos/Brewfile" ]; then
    brew bundle --file "$root/macos/Brewfile"
else
    echo "    SKIPPED: macos/Brewfile not found -- lands in M14." >&2
fi

echo "==> macOS defaults"
if [ -x "$root/macos/defaults.sh" ]; then
    "$root/macos/defaults.sh"
else
    echo "    SKIPPED: macos/defaults.sh not found or not executable -- lands in M16." >&2
fi

echo "==> Done."
