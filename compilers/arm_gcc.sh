#!/bin/bash

# Usage: ./arm_gcc.sh
function install_version() {
    echo "Fetching available versions of ARM None-EABI GCC using xpm..."
    local versions
    versions=$(npm view @xpack-dev-tools/arm-none-eabi-gcc versions --json | jq -r '.[]')
    if [ -z "$versions" ]; then
        echo "No available versions found. Exiting."
        exit 1
    fi
    echo "$versions" | fzf --height 40% --border --prompt "Select a version: " | while read -r version; do
        if [ -n "$version" ]; then
            local install_path="$HOME/.local/xPacks/@xpack-dev-tools/arm-none-eabi-gcc/$version/.content/bin"
            echo "Setting ARM None-EABI GCC version $version..."
            if [ ! -d "$install_path" ]; then
                echo "Installing using xpm..."
                xpm install --global @xpack-dev-tools/arm-none-eabi-gcc@"$version"
            else
                echo "The selected version is already installed."
            fi
            manage_alternatives "$install_path" "$version"
        else
            echo "Installation cancelled or no version selected."
        fi
    done
}

function manage_alternatives() {
    local bin_path=$1
    local version=$2
    sudo update-alternatives --install /usr/bin/arm-none-eabi-gcc arm-none-eabi-gcc "${bin_path}/arm-none-eabi-gcc" 200
    sudo update-alternatives --install /usr/bin/arm-none-eabi-g++ arm-none-eabi-g++ "${bin_path}/arm-none-eabi-g++" 200
    local current_path
    for current_path in $(update-alternatives --query arm-none-eabi-gcc | grep 'Value:' | awk '{print $2}' | grep -v "${bin_path}/arm-none-eabi-gcc"); do
        sudo update-alternatives --install /usr/bin/arm-none-eabi-gcc arm-none-eabi-gcc "$current_path" 100
    done
    for current_path in $(update-alternatives --query arm-none-eabi-g++ | grep 'Value:' | awk '{print $2}' | grep -v "${bin_path}/arm-none-eabi-g++"); do
        sudo update-alternatives --install /usr/bin/arm-none-eabi-g++ arm-none-eabi-g++ "$current_path" 100
    done
}

install_version
