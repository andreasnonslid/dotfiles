# Fish reload functions

function reloadfish
    source $HOME/.config/fish/config.fish
    echo "Fish configuration reloaded."
end

function editfish
    nvim $HOME/.config/fish/config.fish
    echo "Opening Fish configuration."
end
