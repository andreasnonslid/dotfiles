# Shortcuts that came out of measuring what is actually typed (scripts/habits.py).
[ -n "${BASH_VERSION:-}" ] || return 0
case $- in *i*) ;; *) return 0 ;; esac

# rr: compile+run a file, `rr -w file` re-runs on every save
alias rr='"$DOTFILES"/scripts/rr'

# cc / ccr: pick up the last Claude session in this directory / choose one, without pasting an id
alias cc='claude --continue'
alias ccr='claude --resume'

# jj: fuzzy-pick a just recipe (most used first) and edit it before running
jj() {
    command -v just >/dev/null 2>&1 || {
        echo "jj: just is not installed"
        return 1
    }
    local pick recipe line
    pick=$(python3 "$DOTFILES/scripts/jj.py" | fzf --height 40% --reverse --delimiter=$'\t' \
        --with-nth=1,2 --prompt='just > ' --preview-window=hidden) || return 0
    recipe=${pick%%$'\t'*}
    read -e -i "just $recipe " -p '$ ' line || return 0
    [ -n "$line" ] && {
        history -s "$line"
        eval "$line"
    }
}
