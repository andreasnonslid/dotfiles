#!/bin/bash
set -ex

sudo apt update
sudo apt upgrade -y

# Essential libraries and development tools
sudo apt install -y \
    git git-lfs curl build-essential make automake cmake ninja-build \
    libgmp-dev libmpfr-dev libmpc-dev flex bison texinfo unzip wget jq \
    fzf bat ripgrep silversearcher-ag zoxide tldr secure-delete openssh-client \
    tmux xclip libgit2-dev software-properties-common \
    libbz2-dev libncurses5-dev libncursesw5-dev libreadline-dev \
    libsqlite3-dev libffi-dev liblzma-dev tk-dev zlib1g-dev golang fish \
    clang-format-15

sudo locale-gen en_US.UTF-8
sudo update-locale

# Install pyenv only if directory is missing
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
fi
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# Install nvm if not already installed
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node.js LTS and make sure node is available for Neovim
nvm install --lts
nvm use --lts
npm install --global xpm typescript neovim

# Install rustup if not already installed
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
export PATH="$HOME/.cargo/bin:$PATH"

# Python installations
pyenv install -s 3.8.12
pyenv install -s 3.13.0
pyenv global 3.13.0

# Rust packages
cargo install fd-find zellij tealdeer tree-sitter-cli

# Starship prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y

# NVIM latest version install
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage

# Cleanup
sudo apt autoremove -y

set +ex
echo "All tools installed. Use pyenv, nvm, rustup, and xpm for further management."
