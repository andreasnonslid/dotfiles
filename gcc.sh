#!/bin/bash

function set_version {
    # Manually select the default GCC version
    echo "Please select the default GCC version:"
    sudo update-alternatives --config gcc
}

# Check if a version number is provided
if [ -z "$1" ]; then
    echo "No args given, so only sets version, below is usage which builds gcc."
    echo "Usage: $0 <gcc-version-tag>"
    set_version
    exit 1
fi

VERSION=$1
DEV_DIR="$HOME/dev"
GCC_PREFIX="$DEV_DIR/gcc-$VERSION"
GCC_REPO="https://gcc.gnu.org/git/gcc.git"

# Function to add GCC to PATH permanently
function add_to_path {
    echo "export PATH=$GCC_PREFIX/bin:\$PATH" >> $HOME/.profile
}

function set_version {
    # Manually select the default GCC version
    echo "Please select the default GCC version:"
    sudo update-alternatives --config gcc
}

# Ensure development directory exists
mkdir -p $DEV_DIR

# Enter the development directory
cd $DEV_DIR

# Check if the version is already installed
if [ -d "$GCC_PREFIX" ]; then
    echo "GCC version $VERSION is already installed."
    echo "Adding to PATH if not already added..."
    add_to_path
    set_version
    exit 0
fi

# Clone the GCC repository if it doesn't exist
if [ ! -d "gcc" ]; then
    git clone $GCC_REPO
fi

cd gcc

# Fetch all tags and checkout the specified version
git fetch --tags
git checkout "releases/gcc-$VERSION" || exit 1

# Download prerequisites
./contrib/download_prerequisites

# Create build directory
mkdir -p build
cd build

# Configure the GCC build
../configure --prefix=$GCC_PREFIX --enable-languages=c,c++ --disable-multilib

# Compile and install
make -j$(nproc)
sudo make install

# Add to PATH
export PATH=$GCC_PREFIX/bin:$PATH
add_to_path

# Update alternatives
sudo update-alternatives --install /usr/bin/gcc gcc $GCC_PREFIX/bin/gcc 60 --slave /usr/bin/g++ g++ $GCC_PREFIX/bin/g++
sudo update-alternatives --config gcc

set_version
echo "GCC version $VERSION installed successfully and set as default."
