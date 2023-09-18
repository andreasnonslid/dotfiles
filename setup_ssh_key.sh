#!/bin/bash

# Usage: ./setup_ssh_key.sh <action> <name> <email> [options]
#
# Actions:
#   create - Create a new SSH key.
#   delete - Delete an existing SSH key.
#   rename - Rename an existing SSH key.
#   list - List all existing SSH keys.
#
# Options:
#   --RSA - Use RSA key instead of Ed25519.

function list_keys {
    echo "Listing available SSH keys:"
    ls ~/.ssh/id_* | grep -v ".pub$"
}

function delete_key {
    read -p "Enter the key filename to delete (e.g., id_rsa): " key_filename
    key_path="$HOME/.ssh/$key_filename"
    if [[ -f "$key_path" ]]; then
        ssh-add -d "$key_path"
        rm "$key_path" "$key_path.pub"
        echo "Key and its public version deleted, and removed from ssh-agent: $key_path"
    else
        echo "Key not found: $key_path"
    fi
}

function rename_key {
    read -p "Enter the current key filename (e.g., id_rsa): " current_filename
    read -p "Enter the new key filename (e.g., id_rsa_new): " new_filename
    current_path="$HOME/.ssh/$current_filename"
    new_path="$HOME/.ssh/$new_filename"
    if [[ -f "$current_path" ]]; then
        mv "$current_path" "$new_path"
        mv "$current_path.pub" "$new_path.pub"
        ssh-add -d "$current_path"
        ssh-add "$new_path"
        echo "Key renamed and updated in ssh-agent from $current_path to $new_path"
    else
        echo "Key not found: $current_path"
    fi
}

action=$1
name=$2
email=$3
option=$4

case $action in
list)
    list_keys
    ;;
create)
    key_type="ed25519" # Default to Ed25519
    if [[ "$option" == "--RSA" ]]; then
        key_type="rsa"
    fi
    key_file="$HOME/.ssh/id_$key_type"
    i=1
    while [ -e "$key_file" ]; do
        key_file="$HOME/.ssh/id_$key_type_$i"
        i=$((i + 1))
    done
    ssh-keygen -t "$key_type" -C "$name <$email>" -f "$key_file"
    eval "$(ssh-agent -s)"
    ssh-add "$key_file"
    cat "$key_file".pub | xclip -sel clip
    git config --global user.name "$name"
    git config --global user.email "$email"
    echo "SSH key created and added to ssh-agent. Public key copied to clipboard."
    ;;
delete)
    delete_key
    ;;
rename)
    rename_key
    ;;
*)
    echo "Invalid action. Usage: $0 <action> <name> <email> [options]"
    exit 1
    ;;
esac

if [[ "$action" == "create" ]]; then
    echo "Next, go to GitHub and add the public key to your account:"
    echo "1. Open GitHub in your web browser and log in."
    echo "2. Click on your profile picture in the top right corner and select 'Settings'."
    echo "3. Click on 'SSH and GPG keys' in the left sidebar."
    echo "4. Click on 'New SSH key'."
    echo "5. Enter a title for the key (e.g. '$name Laptop') and paste the public key into the 'Key' field."
    echo "6. Click 'Add SSH key'."
fi
