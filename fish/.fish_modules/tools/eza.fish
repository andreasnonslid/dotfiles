# Fish eza aliases

if command -v eza >/dev/null 2>&1
    alias ls='eza --icons --git'
    alias ll='eza -lh --icons --git'
    alias la='eza -lha --icons --git'
    alias lt='eza --tree --icons --git'
else
    alias l='ls -CF'
    alias ll='ls -lh'
    alias la='ls -lha'
end
