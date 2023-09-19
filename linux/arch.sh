#!/bin/bash
set -ex

pacman -Syu --noconfirm

pacman -S --needed --noconfirm \
    base-devel git git-lfs curl automake cmake ninja \
    flex bison texinfo unzip wget jq fzf bat ripgrep \
    the_silver_searcher zoxide tldr eza neovim fish go \
    openssh tmux xclip libgit2 just clang-15 less prettier \
    shfmt stylua python-black taplo-cli go fd

pacman -S --needed --noconfirm \
    openssl zlib xz sqlite readline tk libffi

/usr/bin/pacman -Qi pyenv &>/dev/null || pacman -S --noconfirm pyenv
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

pyenv install --skip-existing 3.11.13
pyenv global 3.11.13
pyenv rehash

pip install cppman
cppman --cache-all

if [ ! -d "$HOME/.nvm" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts && nvm use --lts
npm install --global xpm typescript neovim

if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
export PATH="$HOME/.cargo/bin:$PATH"
cargo install fd-find zellij tealdeer tree-sitter-cli

sed -i 's|^//[[:space:]]*pane_frames[[:space:]]|pane_frames |' ~/.config/zellij/config.kdl

if ! command -v starship &>/dev/null; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

locale-gen en_US.UTF-8
localedef -i en_US -f UTF-8 en_US.UTF-8

pacman -Sc --noconfirm

set +ex
echo "All tools installed. Use pyenv, nvm, rustup and cargo for further management."
