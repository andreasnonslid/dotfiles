# History settings
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT="%F %T "

# Shell behavior
shopt -s checkwinsize
shopt -s globstar 2>/dev/null # Enable ** globbing
shopt -s extglob              # Enable extended globbing

# History search with up/down arrows
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# PATH settings
export PATH="$PATH:/usr/bin"

# GCC colors for better error messages
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Editor settings
export EDITOR='nvim'
alias vim="nvim"

git config --global core.autocrlf input
