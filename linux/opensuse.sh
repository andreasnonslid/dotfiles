#!/bin/bash
set -ex

# zypper prep
sudo zypper refresh
sudo zypper update

# git lfs
sudo zypper install -y git git-lfs

# core build tools
sudo zypper install -y make gcc

# tmux
sudo zypper install -y rust cargo
cargo install zellij

# neovim
sudo zypper install -y neovim python312-neovim
sudo zypper install -y tree-sitter
sudo zypper install -y python3-sqlite3
cd ~/.local/share/nvim/lazy/telescope-fzf-native.nvim
make

# C/C++ supporting tools
sudo zypper install -y cmake make llvm llvm-devel llvm-doc srecord libncurses5 ninja openocd clang15

# Python
sudo zypper install pyenv
pyenv install 3.8.12
pyenv install 3.13.0
pyenv global 3.13.0

# dev tools
sudo zypper install -y xclip ripgrep bat curl jq zoxide just tar update-alternatives
cargo install exa tealdeer

# my install scripts
function confirm_and_execute {
    local command_to_run="$1"
    echo "Command to run: $command_to_run"

    read -p "Do you want to run this? (y/n): " user_response

    case "$user_response" in
        [Yy]* )
            eval "chmod +x $command_to_run"
            eval "$command_to_run"
            ;;
        [Nn]* )
            echo "Command skipped."
            ;;
        * )
            echo "Invalid response. Command skipped."
            ;;
    esac
}

confirm_and_execute "~/dotfiles/arm11.3.sh"

# make sure everything is up to date
sudo zypper update

# Install pyenv
if ! command -v pyenv &>/dev/null; then
  curl https://pyenv.run | bash
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Install nvm
if ! command -v nvm &>/dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install rustup
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Install Node.js LTS and xpm
nvm install --lts
nvm use --lts
npm install --global xpm typescript

# Rust tools
cargo install exa zellij tealdeer

# Neovim and tree-sitter (optional, if not using system package)
sudo zypper install -y neovim tree-sitter

# Run ARM toolchain install script if desired
chmod +x ~/dotfiles/arm11.3.sh && ~/dotfiles/arm11.3.sh

sudo zypper update
set +ex
