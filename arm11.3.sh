#!/bin/bash
set -e

# === Configuration ===
GCC_VERSION="11.3.rel1"
GDB_VERSION="13.3.rel1"
GCC_DIR="/usr/local/arm-gnu-toolchain-${GCC_VERSION}-x86_64-arm-none-eabi"
GDB_DIR="/usr/local/arm-gnu-toolchain-${GDB_VERSION}-x86_64-arm-none-eabi"

# === Helper ===
function is_installed {
    [ -x "$1" ]
}

# === Install GCC toolchain ===
if is_installed "$GCC_DIR/bin/arm-none-eabi-gcc"; then
    echo "ARM GCC ${GCC_VERSION} already installed."
else
    echo "Downloading ARM GCC ${GCC_VERSION}..."
    curl -LO "https://developer.arm.com/-/media/Files/downloads/gnu/${GCC_VERSION}/binrel/arm-gnu-toolchain-${GCC_VERSION}-x86_64-arm-none-eabi.tar.xz"
    echo "Extracting GCC..."
    sudo tar -xJf "arm-gnu-toolchain-${GCC_VERSION}-x86_64-arm-none-eabi.tar.xz" -C /usr/local
    rm -f "arm-gnu-toolchain-${GCC_VERSION}-x86_64-arm-none-eabi.tar.xz"
fi

# === Install newer GDB (13.3) ===
if is_installed "$GDB_DIR/bin/arm-none-eabi-gdb"; then
    echo "ARM GDB ${GDB_VERSION} already installed."
else
    echo "Downloading ARM GDB ${GDB_VERSION}..."
    curl -LO "https://developer.arm.com/-/media/Files/downloads/gnu/${GDB_VERSION}/binrel/arm-gnu-toolchain-${GDB_VERSION}-x86_64-arm-none-eabi.tar.xz"
    echo "Extracting GDB..."
    sudo tar -xJf "arm-gnu-toolchain-${GDB_VERSION}-x86_64-arm-none-eabi.tar.xz" -C /usr/local
    rm -f "arm-gnu-toolchain-${GDB_VERSION}-x86_64-arm-none-eabi.tar.xz"
fi

# === Register binaries ===
function setup_alternative {
    tool=$1
    path=$2
    if [ -f "$path" ]; then
        sudo update-alternatives --install "/usr/bin/$tool" "$tool" "$path" 100
    else
        echo "⚠️  Missing: $path"
    fi
}

# Compiler tools from GCC 11.3
setup_alternative "arm-none-eabi-gcc" "$GCC_DIR/bin/arm-none-eabi-gcc"
setup_alternative "arm-none-eabi-g++" "$GCC_DIR/bin/arm-none-eabi-g++"
setup_alternative "arm-none-eabi-objcopy" "$GCC_DIR/bin/arm-none-eabi-objcopy"
setup_alternative "arm-none-eabi-size" "$GCC_DIR/bin/arm-none-eabi-size"
setup_alternative "arm-none-eabi-objdump" "$GCC_DIR/bin/arm-none-eabi-objdump"
setup_alternative "arm-none-eabi-nm" "$GCC_DIR/bin/arm-none-eabi-nm"

# Debugger from GDB 13.3
setup_alternative "arm-none-eabi-gdb" "$GDB_DIR/bin/arm-none-eabi-gdb"

# Harmless link for libncursesw.so.5 backwards compat
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncursesw.so.6 /usr/lib/x86_64-linux-gnu/libncursesw.so.5
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

# === Final verification ===
echo
echo "Installed toolchain versions:"
arm-none-eabi-gcc --version | head -n1
arm-none-eabi-gdb --version | head -n1

echo
echo "✅ Setup complete: GCC ${GCC_VERSION}, GDB ${GDB_VERSION}"
