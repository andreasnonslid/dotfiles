alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
if command -v fd >/dev/null 2>&1; then
    alias fd='fd'
else
    alias fd='find . -type f -name'
fi
alias ffind='find . -type f -name'

maliases() {
    rg -e "^alias.*$1.*" ~/dotfiles/bashrc/.bashrc ~/dotfiles/bashrc/.shell_modules --no-ignore --hidden --glob "*.sh" --glob "*.bashrc"
}

search() {
    if [ $# -lt 1 ]; then
        echo "Usage: search PATTERN [RG_ARGS...]"
        return 1
    fi

    local pattern="$1"
    shift
    local extra_args=("$@")

    rg -l --hidden --no-ignore "$pattern" . "${extra_args[@]}"
}

replace() {
    if [ $# -lt 2 ]; then
        echo "Usage: replace OLD_TEXT NEW_TEXT [RG_ARGS...]"
        echo "Note: Uses search PATTERN --null [RG_ARGS...] for finding files to replace in"
        return 1
    fi

    local old="$1"
    local new="$2"
    shift 2
    local extra=("$@")

    # Use perl for literal replacement (avoids sed regex/special-char issues)
    local new_escaped
    new_escaped=$(printf '%s' "$new" | sed 's/\\/\\\\/g; s/\$/\\$/g')
    export REPLACE_OLD="$old" REPLACE_NEW="$new_escaped"
    search "$old" "${extra[@]}" --null | xargs -0 perl -i -pe 's/\Q$ENV{REPLACE_OLD}\E/$ENV{REPLACE_NEW}/g'
}
