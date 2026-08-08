#!/usr/bin/env bash

# Usage: ./setup_git_host.sh <host> <key-domain>
#
# Adds a Host block for <host> to ~/.local/secrets/ssh/<host>.conf, which
# the tracked ~/.ssh/config (M30, bashrc/.ssh/config) pulls in via its
# `Include ~/.local/secrets/ssh/*.conf` line. Host entries stay out of git
# this way, the same as the work git identity in
# ~/.local/secrets/git/work.gitconfig (see README.md).
#
# <key-domain> is matched against the email in each ~/.ssh/*.pub comment
# (as written by setup_ssh_key.sh: `ssh-keygen -C "name <email>"`) to find
# the right key automatically -- no need to name the key file directly.
#
# Example (replaces the old AutoStore-only setup_AS_git.sh):
#   ./setup_git_host.sh as-git.autostoresystem.com autostoresystem.com

set -euo pipefail

host=${1:-}
key_domain=${2:-}

if [[ -z "$host" || -z "$key_domain" ]]; then
    echo "Usage: $0 <host> <key-domain>" >&2
    exit 1
fi

key_path=$(grep -l "@${key_domain}" "$HOME"/.ssh/*.pub 2>/dev/null | sed 's/\.pub$//' | head -n1)

if [[ -z "$key_path" ]]; then
    echo "No SSH key found with @${key_domain}"
    exit 1
fi

secrets_dir="$HOME/.local/secrets/ssh"
conf_file="$secrets_dir/${host}.conf"

mkdir -p "$secrets_dir"
chmod 700 "$secrets_dir"

if [[ -f "$conf_file" ]] && grep -qi "Host[[:space:]]\+${host}" "$conf_file"; then
    echo "Entry for $host already exists in $conf_file."
else
    echo "Adding entry for $host to $conf_file..."
    cat <<EOF >>"$conf_file"
Host $host
    HostName $host
    IdentityFile $key_path
    IdentitiesOnly yes
EOF
fi

chmod 600 "$conf_file"

if [[ -e "$HOME/.ssh/config" ]]; then
    chmod 600 "$HOME/.ssh/config"
else
    echo "Warning: ~/.ssh/config not found -- run ./bootstrap.sh first so" \
        "its tracked Include picks up $conf_file." >&2
fi
