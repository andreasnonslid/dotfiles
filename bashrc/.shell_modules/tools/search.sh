alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
if command -v fd >/dev/null 2>&1; then
    alias fd='fd-find'
else
    alias fd='find . -type f -name'
fi
alias ffind='find . -type f -name'

maliases() {
    rg -e "^alias.*$1.*" ~/dotfiles/bashrc/.bashrc ~/dotfiles/bashrc/.shell_modules --no-ignore --hidden --glob "*.sh" --glob "*.bashrc"
}
