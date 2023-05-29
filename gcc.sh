#!/bin/bash

function set_version {
    echo "Please select the default GCC version:"
    sudo update-alternatives --config gcc
}

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

function add_to_path {
    echo "export PATH=$GCC_PREFIX/bin:\$PATH" >> $HOME/.profile
}

function set_version {
    echo "Please select the default GCC version:"
    sudo update-alternatives --config gcc
}

mkdir -p $DEV_DIR
cd $DEV_DIR

if [ -d "$GCC_PREFIX" ]; then
    echo "GCC version $VERSION is already installed."
    echo "Adding to PATH if not already added..."
    add_to_path
    set_version
    exit 0
fi

if [ ! -d "gcc" ]; then
    git clone $GCC_REPO
fi

cd gcc
git fetch --tags
git checkout "releases/gcc-$VERSION" || exit 1
./contrib/download_prerequisites
mkdir -p build
cd build
../configure --prefix=$GCC_PREFIX --enable-languages=c,c++ --disable-multilib
make -j$(nproc)
sudo make install
export PATH=$GCC_PREFIX/bin:$PATH
add_to_path
sudo update-alternatives --install /usr/bin/gcc gcc $GCC_PREFIX/bin/gcc 60 --slave /usr/bin/g++ g++ $GCC_PREFIX/bin/g++
sudo update-alternatives --config gcc
set_version
echo "GCC version $VERSION installed successfully and set as default."
