# zypper prep
sudo zypper refresh
sudo zupper update

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
