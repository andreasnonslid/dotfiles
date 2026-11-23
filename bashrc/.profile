# Ensure ~/.local/bin is at the front of PATH for interceptor scripts
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Docker Desktop CLI tools (it appends a hard-coded copy of this on install)
if [ -d "$HOME/.docker/bin" ]; then
    PATH="$PATH:$HOME/.docker/bin"
fi

# Add tools scripts directory
if [ -d "$HOME/tools/scripts" ]; then
    PATH="$PATH:$HOME/tools/scripts"
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# macOS bash login shells read .profile, not .bashrc — pull in the full config.
if [ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
