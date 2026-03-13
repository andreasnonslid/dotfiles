alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

if command -v fd >/dev/null 2>&1; then
    alias ff='fd --hidden --follow'
    alias ffd='fd --hidden --follow --type d'
    alias fff='fd --hidden --follow --type f'
else
    alias ff='find . -name'
    alias ffd='find . -type d -name'
    alias fff='find . -type f -name'
fi
alias ffind='find . -type f -name'

maliases() {
    local dotfiles="${DOTFILES:-$HOME/dotfiles}"
    rg -e "^alias.*$1.*" -e "^wfn.*$1.*" "$dotfiles/bashrc/.bashrc" "$dotfiles/bashrc/.shell_modules" --no-ignore --hidden --glob "*.sh" --glob "*.bashrc"
}
wfn maliases "Search aliases and wrapped functions"

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
wfn search "Ripgrep file search in current directory"

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
wfn replace "Find and replace text across files"
