# Ensure ~/.local/bin is at the front of PATH for interceptor scripts
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Add tools scripts directory
if [ -d "$HOME/tools/scripts" ]; then
    PATH="$PATH:$HOME/tools/scripts"
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
