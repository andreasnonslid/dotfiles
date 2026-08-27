reloadbash() {
    cd "${DOTFILES:-$HOME/dotfiles}" || return 1
    source "$HOME/.bashrc"
    # shellcheck disable=SC2103  # source must affect this shell, not a subshell
    cd - >/dev/null || return 1
    echo "Bash configuration reloaded."
}
wfn reloadbash "Reload bash configuration"

editbash() {
    nvim "$HOME/.bashrc"
    echo "Opening Bash configuration."
}
wfn editbash "Open bash config in nvim"
