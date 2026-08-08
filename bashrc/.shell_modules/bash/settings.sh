# bash-only shell behavior: shopt and readline bind settings.
#
# Split out of core/settings.sh (M06) so core/ stays sourceable by zsh too --
# shopt and bind are bash builtins with no zsh equivalent. Sourced last by
# .bashrc, after core/git/tools, as the bash adapter.

# History behavior
shopt -s histappend

# Shell behavior
shopt -s checkwinsize
shopt -s globstar 2>/dev/null # Enable ** globbing
shopt -s extglob              # Enable extended globbing

# Completion settings
if ! shopt -oq posix; then
    shopt -s progcomp
    bind 'set show-all-if-ambiguous on'
    bind 'set completion-ignore-case on'
    bind '"\t": menu-complete'
    bind '"\e[Z": menu-complete-backward'
fi

# History search with up/down arrows
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
