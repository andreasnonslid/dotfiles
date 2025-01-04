# Fish settings

# History settings
set -gx HISTSIZE 100000
set -gx HISTFILESIZE 200000
set -gx HISTTIMEFORMAT "%F %T "

# PATH settings
set -gx PATH $PATH /usr/bin

# GCC colors for better error messages
set -gx GCC_COLORS 'error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Editor settings
set -gx EDITOR nvim
alias vim="nvim"
git config --global core.autocrlf input
