#!/bin/bash
set -ex

sudo zypper refresh
sudo zypper update
sudo zypper install -y git git-lfs
sudo zypper install -y make gcc
sudo zypper install -y rust cargo
cargo install zellij
sudo zypper install -y neovim python312-neovim
sudo zypper install -y tree-sitter
sudo zypper install -y python3-sqlite3
cd ~/.local/share/nvim/lazy/telescope-fzf-native.nvim
make
sudo zypper install -y cmake make llvm llvm-devel llvm-doc srecord libncurses5 ninja openocd clang15
sudo zypper install pyenv
pyenv install -s 3.8.12
pyenv install -s 3.13.0
pyenv global 3.13.0
sudo zypper install -y xclip ripgrep fd bat curl jq zoxide just tar update-alternatives
sudo zypper install -y exa

function confirm_and_execute {
    local command_to_run="$1"
    echo "Command to run: $command_to_run"

    read -p "Do you want to run this? (y/n): " user_response

    case "$user_response" in
    [Yy]*)
        eval "chmod +x $command_to_run"
        eval "$command_to_run"
        ;;
    [Nn]*)
        echo "Command skipped."
        ;;
    *)
        echo "Invalid response. Command skipped."
        ;;
    esac
}

confirm_and_execute "~/dotfiles/arm11.3.sh"

sudo zypper update

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

# Install rustup
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
fi

nvm install --lts
nvm use --lts
npm install --global xpm typescript
cargo install exa zellij tealdeer
sudo zypper install -y neovim tree-sitter
chmod +x ~/dotfiles/arm11.3.sh && ~/dotfiles/arm11.3.sh
sudo zypper update
set +ex
