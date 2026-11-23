# macOS Homebrew PATH wiring (M13).
#
# macos/install.sh evals brew shellenv for its own process only. This makes
# brew available in every interactive shell on darwin without touching Linux.
# $OSTYPE and a prefix check instead of `uname` keep this spawn-free; bash
# caches the shellenv output (rebuilt when brew itself is updated).
case "${OSTYPE:-}" in
darwin*)
    if [ -x /opt/homebrew/bin/brew ]; then
        brew_prefix=/opt/homebrew
    else
        brew_prefix=/usr/local
    fi
    if [ -x "$brew_prefix/bin/brew" ]; then
        if command -v __cached_init >/dev/null 2>&1; then
            __cached_init brew-shellenv "$brew_prefix/bin/brew" shellenv
        else
            eval "$("$brew_prefix/bin/brew" shellenv)"
        fi
    fi
    ;;
esac
