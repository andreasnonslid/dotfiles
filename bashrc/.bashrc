# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

export DOTFILES="$HOME/dotfiles"

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
    source "$config_file"
done

if command -v is_wsl >/dev/null 2>&1 && is_wsl; then
    source ~/.shell_modules/tools/wsl.sh
fi

# Source the bash adapter (shopt/bind settings that don't exist in zsh, M06)
for config_file in ~/.shell_modules/bash/*.sh; do
    source "$config_file"
done

# Source any remaining scripts
# for config_file in ~/.shell_modules/scripts/*.sh; do
#     source "$config_file"
# done

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# SHELL PROMPT (M07: starship replaces the hand-rolled PS1/PROMPT_COMMAND)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
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
            _nvim_dir="$(dirname "$_nvim_bin")"
            export PATH="$_nvim_dir:$PATH"
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

# Optional: Start Zellij on interactive shells
# Uncomment the following lines to enable Zellij auto-start:
if [[ $- == *i* ]]; then
    if [ -z "$ZELLIJ" ] && [ -z "$TMUX" ]; then
        if command -v zellij >/dev/null 2>&1; then
            zellij
        fi
    fi
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
