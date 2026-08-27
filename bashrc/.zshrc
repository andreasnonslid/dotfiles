# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

export DOTFILES="$HOME/dotfiles"

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

# Source tool configurations
for config_file in ~/.shell_modules/tools/*.sh; do
    source "$config_file"
done

# Source the zsh adapter (compsys completions, M11; anything else zsh-only)
for config_file in ~/.shell_modules/zsh/*.sh(N); do
    source "$config_file"
done

# History (zsh option names for core/settings.sh's HISTCONTROL=ignoreboth:
# erasedups / HISTFILESIZE=200000 -- HISTSIZE itself is already set there
# and applies to zsh unchanged)
HISTFILE="$HOME/.zsh_history"
SAVEHIST=200000
setopt EXTENDED_HISTORY      # store timestamps, like HISTTIMEFORMAT
setopt HIST_IGNORE_SPACE     # the "ignore" half of ignoreboth
setopt HIST_IGNORE_DUPS
setopt HIST_EXPIRE_DUPS_FIRST # the "erasedups" half
setopt HIST_SAVE_NO_DUPS

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# mise activation lives in tools/mise.sh (M22), sourced by the tools/ loop
# above -- shared with .bashrc rather than duplicated here.

# SHELL PROMPT (starship, matching the bash M07 setup)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# PATH settings -- macOS/zsh subset of .bashrc's list. Linux-only entries
# (/opt/nvim-linux-x86_64, STM32_PRG_PATH, the WSL openocd interceptor
# ordering) are guarded by lib/os.sh in M10 and have no place in this file.
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$PATH:$HOME/tools/scripts"

# .cargo/env owns $HOME/.cargo/bin. It used to also be exported by hand earlier
# in this file, which duplicated the entry on rustup versions whose env file is
# unguarded; this is now the single place it enters PATH.
# shellcheck source=/dev/null
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
