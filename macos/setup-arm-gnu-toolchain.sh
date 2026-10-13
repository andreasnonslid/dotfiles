#!/usr/bin/env bash
# Symlink Arm GNU Toolchain into ~/.local/bin.
set -euo pipefail

TOOLCHAIN_BIN="${ARM_GNU_TOOLCHAIN_BIN:-$HOME/Applications/ArmGNUToolchain/15.3.rel1/arm-none-eabi/bin}"
LINK_DIR="${HOME}/.local/bin"

if [[ ! -x "${TOOLCHAIN_BIN}/arm-none-eabi-gcc" ]]; then
    echo "Arm GNU Toolchain not found at: ${TOOLCHAIN_BIN}" >&2
    echo "Install with: installer -pkg <arm-gnu-toolchain-*.pkg> -target CurrentUserHomeDirectory" >&2
    echo "Or set ARM_GNU_TOOLCHAIN_BIN to the toolchain bin directory." >&2
    exit 1
fi

mkdir -p "${LINK_DIR}"

linked=0
for tool in "${TOOLCHAIN_BIN}"/arm-none-eabi-*; do
    name="$(basename "${tool}")"
    link="${LINK_DIR}/${name}"
    if [[ -L "${link}" ]]; then
        rm -f "${link}"
    elif [[ -e "${link}" ]]; then
        echo "skip ${name}: ${link} exists and is not a symlink" >&2
        continue
    fi
    ln -s "${tool}" "${link}"
    linked=$((linked + 1))
done

echo "Linked ${linked} arm-none-eabi tools into ${LINK_DIR}"
echo "Verify: arm-none-eabi-gcc --version"
