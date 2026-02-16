reloadbash() {
    cd "${DOTFILES:-$HOME/dotfiles}"
    source "$HOME/.bashrc"
    cd - >/dev/null
    echo "Bash configuration reloaded."
}
wfn reloadbash "Reload bash configuration"

editbash() {
    nvim $HOME/.bashrc
    echo "Opening Bash configuration."
}
wfn editbash "Open bash config in nvim"
