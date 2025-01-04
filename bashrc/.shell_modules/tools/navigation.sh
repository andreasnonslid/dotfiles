if command -v zoxide >/dev/null 2>&1; then
    cd() {
        if builtin cd "$@" 2>/dev/null; then
            zoxide add "$(pwd)" 2>/dev/null
            return 0
        fi

        local zpath=$(zoxide query "$1" 2>/dev/null)
        if [ -n "$zpath" ]; then
            builtin cd "$zpath" && zoxide add "$zpath" 2>/dev/null
            return 0
        fi

        echo "cd: no such directory or zoxide entry: $1"
        return 1
    }
fi

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

mkcd() {
    mkdir -p "$1" && cd "$1"
}
