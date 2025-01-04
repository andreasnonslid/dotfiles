# Fish configuration

# Source core settings
for config_file in ~/.config/fish/.fish_modules/core/*.fish
    source "$config_file"
end

# Source git configuration
for config_file in ~/.config/fish/.fish_modules/git/*.fish
    source "$config_file"
end

# Source tool configurations
for config_file in ~/.config/fish/.fish_modules/tools/*.fish
    source "$config_file"
end

# Initialize zoxide if available
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

# Enable Starship prompt on startup
starship init fish | source

# Start Zellij on interactive shells
if status is-interactive
    if not set -q ZELLIJ
        if test -z "$TMUX"
            zellij
        end
    end
end

# 1. Tell Fish where pyenv lives
set -gx PYENV_ROOT $HOME/.pyenv

# 2. Prepend pyenv shims and bin to PATH
set -gx PATH $PYENV_ROOT/shims $PYENV_ROOT/bin $PATH

# 3. Ensure shims are activated for login shells
status is-login; and source (pyenv init --path | psub)

# 4. Enable full pyenv in interactive shells (completions, 'pyenv shell', etc.)
status is-interactive; and source (pyenv init - | psub)
