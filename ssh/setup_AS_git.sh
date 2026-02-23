#!/usr/bin/env bash

KEY_PATH=$(grep -l '@autostoresystem\.com' ~/.ssh/*.pub 2>/dev/null | sed 's/\.pub$//' | head -n1)

if [[ -z "$KEY_PATH" ]]; then
    echo "No SSH key found with @autostoresystem.com"
    exit 1
fi

if [[ ! -f ~/.ssh/config ]]; then
    echo "~/.ssh/config does not exist. Creating and adding entry."
    touch ~/.ssh/config
fi

if grep -qi 'Host[[:space:]]\+as-git.autostoresystem.com' ~/.ssh/config; then
    echo "Entry for as-git.autostoresystem.com already exists."
else
    echo "Adding entry for as-git.autostoresystem.com..."
    cat <<EOF >>~/.ssh/config

Host as-git.autostoresystem.com
    HostName as-git.autostoresystem.com
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
EOF
fi

chmod 600 ~/.ssh/config
