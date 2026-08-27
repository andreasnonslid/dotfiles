# History settings
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT="%F %T "

# GCC colors for better error messages
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Editor settings
export EDITOR='nvim'
alias vim="nvim"

# Shared shortcuts. These live here rather than in .bashrc/.zshrc so there is
# one definition instead of two that can drift apart.
alias cheat="curl cheat.sh/"
alias help="tldr"

# Ripgrep config
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
