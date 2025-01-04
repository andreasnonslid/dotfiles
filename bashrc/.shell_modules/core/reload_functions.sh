reloadbash() {
    cd ~/dotfiles
    source $HOME/.bashrc
    cd - >/dev/null
    echo "Bash configuration reloaded."
}

editbash() {
    nvim $HOME/.bashrc
    echo "Opening Bash configuration."
}
