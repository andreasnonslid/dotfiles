#!/bin/bash
INSTALL_DIR="/usr/local/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-eabi"

function is_installed {
    type "$1" >/dev/null 2>&1
}

if is_installed $INSTALL_DIR/bin/arm-none-eabi-gcc; then
    echo "ARM GNU Toolchain is already installed."
else
    echo "Downloading ARM GNU Toolchain..."
    curl -LO "https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-eabi.tar.xz?rev=95edb5e17b9d43f28c74ce824f9c6f10&hash=176C4D884DBABB657ADC2AC886C8C095409547C4"
    echo "Extracting..."
    sudo tar xJf arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-eabi.tar.xz -C /usr/local
fi

function setup_alternative {
    tool=$1
    path="$INSTALL_DIR/bin/$tool"
    if [ -f "$path" ]; then
        sudo update-alternatives --install "/usr/bin/$tool" "$tool" "$path" 100
        sudo update-alternatives --config "$tool"
    else
        echo "Executable $tool not found."
    fi
}

setup_alternative "arm-none-eabi-gcc"
setup_alternative "arm-none-eabi-g++"
setup_alternative "arm-none-eabi-objcopy"
setup_alternative "arm-none-eabi-size"
setup_alternative "arm-none-eabi-gdb"
setup_alternative "arm-none-eabi-objdump"
setup_alternative "arm-none-eabi-nm"

# to make arm-none-eabi-gdb work
export PYTHONHOME=$(pyenv prefix 3.8.12)
export PYTHONPATH=$PYTHONHOME/lib/python3.8
unset PYTHONHOME
unset PYTHONPATH
