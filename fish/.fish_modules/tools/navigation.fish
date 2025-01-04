# Fish navigation

if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

function mkcd
    mkdir -p "$argv[1]" && cd "$argv[1]"
end
