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

    # null separated filenames passed to sed
    search "$old" "${extra[@]}" --null | xargs -0 sed -i "s|$old|$new|g"
}
