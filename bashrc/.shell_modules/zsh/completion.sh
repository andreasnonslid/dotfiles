# zsh completion adapter: compsys equivalents of bash/completion.sh.
#
# bash-completion's __git_complete/complete builtins (bash/completion.sh)
# have no zsh equivalent -- zsh uses its own compsys (compinit/compdef).
# This mirrors every git alias completion plus the gcmp/rs/rh custom
# completions so tab-completion isn't lost when a shell moves to zsh.
#
# .bashrc/.zshrc export $DOTFILES before sourcing anything under
# .shell_modules (see tools/clipboard.sh), so it is already set here.

# Initialise compsys. A fresh Homebrew zsh often leaves completion dirs
# group/other-writable, which trips compaudit's security check and
# silently disables completion -- fix the perms instead of bypassing
# the check with `compinit -u`.
autoload -Uz compinit
__completion_insecure_dirs="$(compaudit 2>/dev/null)"
if [ -n "$__completion_insecure_dirs" ]; then
    echo "$__completion_insecure_dirs" | xargs chmod go-w 2>/dev/null
fi
unset __completion_insecure_dirs
compinit

# Case-insensitive matching, to match the bash `completion-ignore-case`
# bind in bash/settings.sh.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Git alias completions -- generated from tools/completion.sh's
# `__git_complete ALIAS git_SUBCOMMAND` lines rather than duplicated by
# hand, so the ~45-alias list can't drift between the two shells. zsh's
# `_git` recognises the synthetic "git-SUBCOMMAND" command name for this
# exact purpose.
__completion_dotfiles="${DOTFILES:-$HOME/dotfiles}"
__completion_bash_src="$__completion_dotfiles/bashrc/.shell_modules"
__completion_bash_src="$__completion_bash_src/tools/completion.sh"
if [ -r "$__completion_bash_src" ]; then
    while read -r __completion_alias __completion_target; do
        compdef _git \
            "$__completion_alias=${__completion_target/git_/git-}"
    done < <(grep -oE '__git_complete [a-zA-Z_]+ git_[a-zA-Z_]+' \
        "$__completion_bash_src" | awk '{print $2, $3}')
fi
unset __completion_dotfiles __completion_bash_src
unset __completion_alias __completion_target

# Custom completions, ported 1:1 from tools/completion.sh.
_gcmp() {
    local -a branches
    local __line
    while IFS= read -r __line; do
        [ -n "$__line" ] && branches+=("$__line")
    done < <(git branch --format='%(refname:short)' 2>/dev/null)
    _describe 'branch' branches
}
compdef _gcmp gcmp

_rs() {
    local -a counts
    # shellcheck disable=SC2034  # consumed by _describe via array name
    counts=(1 2 3 4 5)
    _describe 'commit count' counts
}
compdef _rs rs

_rh() {
    local -a counts
    # shellcheck disable=SC2034  # consumed by _describe via array name
    counts=(1 2 3 4 5)
    _describe 'commit count' counts
}
compdef _rh rh
