#!/bin/bash
set -ex

sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl build-essential make automake cmake ninja-build libgmp-dev libmpfr-dev libmpc-dev flex bison texinfo unzip wget jq fzf bat ripgrep silversearcher-ag zoxide tldr secure-delete openssh-client tmux xclip libgit2-dev exa

if ! command -v pyenv &>/dev/null; then
  curl https://pyenv.run | bash
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

if ! command -v nvm &>/dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

nvm install --lts
nvm use --lts
npm install --global xpm typescript
pyenv install -s 3.8.12
pyenv install -s 3.13.0
pyenv global 3.13.0
cargo install fd-find zellij tealdeer
sudo apt install -y golang
curl -sS https://starship.rs/install.sh | sh -s -- -y
sudo apt autoremove -y
echo "All version managers and tools installed. Use pyenv, nvm, rustup, and xpm for further tool management."
set +ex
