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
wfn mkcd "Create directory and cd into it"

# After cd (or a zoxide jump) show what is there, so the usual `cd x` then `ls` is one step.
# Big directories are cut off; interactive shells only.
if [ -n "${BASH_VERSION:-}" ] && [[ $- == *i* ]]; then
    __NAV_LAST_PWD=$PWD
    __nav_auto_ls() {
        local rc=$?
        if [ "$PWD" != "$__NAV_LAST_PWD" ]; then
            __NAV_LAST_PWD=$PWD
            local n
            n=$(command ls -A 2>/dev/null | wc -l)
            if [ "$n" -gt 0 ] && [ "$n" -le 200 ]; then
                if [ "$n" -gt 40 ]; then
                    ls 2>/dev/null | head -n 40
                    printf '\e[2m  \u2026 %s entries\e[0m\n' "$n"
                else ls; fi
            elif [ "$n" -gt 200 ]; then
                printf '\e[2m  %s entries\e[0m\n' "$n"
            fi
        fi
        return $rc
    }
    case ";${PROMPT_COMMAND:-};" in
    *";__nav_auto_ls;"*) ;;
    *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}__nav_auto_ls" ;;
    esac
fi
