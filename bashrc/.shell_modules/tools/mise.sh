# mise -- single activation line, shared by bash and zsh (M22).
#
# Replaces the pyenv and nvm init blocks that used to live in .bashrc.
# rustup/~/.cargo/env is left alone -- mise adds nothing there.
#
# tools/*.sh is sourced by both .bashrc and .zshrc from the same loop, so
# this detects which shell is running rather than shipping one copy per
# adapter, matching tools/clipboard.sh's runtime-dispatch approach.
if command -v mise >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(mise activate zsh)"
    elif [ -n "${BASH_VERSION:-}" ]; then
        eval "$(mise activate bash)"
    fi
fi
