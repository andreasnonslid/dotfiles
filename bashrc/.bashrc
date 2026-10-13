# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Ghostty spawns bash --posix --login. POSIX mode breaks bash extensions
# ([[, ${arr@Q}, alias expansion) used throughout .shell_modules.
set +o posix 2>/dev/null
shopt -s expand_aliases 2>/dev/null

export DOTFILES="$HOME/dotfiles"

# Start Zellij first, before the (slow) rc below: the shell Zellij spawns loads the rc itself,
# so doing it here avoids paying for it twice on every new terminal.
if [ -z "$ZELLIJ" ] && [ -z "$TMUX" ]; then
    PATH="$HOME/.cargo/bin:$PATH"
    if command -v zellij >/dev/null 2>&1; then
        zellij
    fi
fi

# OS predicates (is_linux, is_wsl, ...) used below to guard Linux/WSL-only
# bits (M10) instead of the silent command -v fallbacks that used to hide
# them being wrong on other platforms.
# shellcheck source=/dev/null
[ -r "$DOTFILES/lib/os.sh" ] && . "$DOTFILES/lib/os.sh"

# Source non-git-tracked auth/secrets if present
[ -f "$DOTFILES/bashrc/auth.sh" ] && source "$DOTFILES/bashrc/auth.sh"

# GitLab PAT for @autostore npm (read_api); used by ~/.npmrc ${GITLAB_ACCESS_KEY}
[ -f "$HOME/.config/autostore/gitlab-npm.env" ] && . "$HOME/.config/autostore/gitlab-npm.env"

# Source core settings first
for config_file in ~/.shell_modules/core/*.sh; do
    source "$config_file"
done

# Source git configuration
for config_file in ~/.shell_modules/git/*.sh; do
    source "$config_file"
done

# Source tool configurations. wsl.sh is WSL-only (M10) -- sourced
# separately below via is_wsl instead of unconditionally here.
for config_file in ~/.shell_modules/tools/*.sh; do
    [ "$(basename "$config_file")" = wsl.sh ] && continue
    # completion.sh costs ~45 ms; it is loaded on the first Tab instead (below).
    [ "$(basename "$config_file")" = completion.sh ] && continue
    source "$config_file"
done

if command -v is_wsl >/dev/null 2>&1 && is_wsl; then
    source ~/.shell_modules/tools/wsl.sh
fi

# Source the bash adapter (shopt/bind settings that don't exist in zsh, M06)
for config_file in ~/.shell_modules/bash/*.sh; do
    source "$config_file"
done

# Load bash-completion on the first Tab press, not at startup. The macro runs the loader and then
# the normal completion, so the first Tab behaves exactly like every later one.
__lazy_completion() {
    [ -n "${__completion_loaded:-}" ] && return
    __completion_loaded=1
    source ~/.shell_modules/tools/completion.sh
}
bind -x '"\C-x\C-a": __lazy_completion'
bind '"\C-x\C-b": menu-complete'
bind '"\t": "\C-x\C-a\C-x\C-b"'

# Source any remaining scripts
# for config_file in ~/.shell_modules/scripts/*.sh; do
#     source "$config_file"
# done

# Cached `<tool> init` output: saves a process spawn per tool on every shell start.
# Rebuilt when the tool binary is newer than the cache (i.e. after an upgrade).
__cached_init() {
    local name=$1 bin cache
    shift
    bin=$(command -v "$1") || return 1
    cache="${XDG_CACHE_HOME:-$HOME/.cache}/shell-init/$name.sh"
    if [ ! -s "$cache" ] || [ "$bin" -nt "$cache" ]; then
        mkdir -p "${cache%/*}"
        "$@" > "$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache"
    fi
    . "$cache"
}

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
    __cached_init zoxide zoxide init bash
fi

# SHELL PROMPT (M07: starship replaces the hand-rolled PS1/PROMPT_COMMAND)
if command -v starship >/dev/null 2>&1; then
    __cached_init starship starship init bash --print-full-init
fi

# Helpful aliases
alias cheat="curl cheat.sh/"
alias help="tldr"

# PATH settings
export PATH="$HOME/.cargo/bin:$PATH"

# Prefer release tarball over distro neovim (M10: skip on macOS).
if command -v is_linux >/dev/null 2>&1 && is_linux; then
    for _nvim_bin in \
        "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" \
        "/opt/nvim-linux-x86_64/bin/nvim"; do
        if [ -x "$_nvim_bin" ]; then
            export PATH="$(dirname "$_nvim_bin"):$PATH"
            break
        fi
    done
fi

# Call Fish for interactive shells
# if [[ $- == *i* ]]; then
#     if command -v fish >/dev/null 2>&1; then
#         exec fish
#     fi
# fi

# ST-Link WSL bridge: interceptor must come before /usr/bin/openocd
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$PATH:$HOME/tools/scripts"

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export PATH="$HOME/flutter/bin:$PATH"
