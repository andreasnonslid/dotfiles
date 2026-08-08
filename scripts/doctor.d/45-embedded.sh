#!/usr/bin/env bash
# scripts/doctor.d/45-embedded.sh -- ARM embedded toolchain shims (M25).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# macos/embedded.sh is opt-in (not run by macos/install.sh), so an absent
# toolchain is expected on a machine that hasn't needed it yet -- WARN, not
# FAIL. What this actually guards against is the failure mode specific to
# the ~/.local/bin symlink approach: a shim left pointing at an xPack
# version that was since removed, which `command -v` alone can't catch
# since it only checks the symlink exists, not that it resolves.

embedded_bin="$HOME/.local/bin/arm-none-eabi-gcc"

if [ -L "$embedded_bin" ] && [ ! -e "$embedded_bin" ]; then
    doctor_fail "embedded-toolchain" "arm-none-eabi-gcc shim is a dangling symlink" \
        "The xPack version it pointed to was likely removed. Re-run ./macos/embedded.sh to reactivate a version."
elif [ ! -e "$embedded_bin" ]; then
    doctor_warn "embedded-toolchain" "arm-none-eabi-gcc not installed" \
        "Opt-in -- run ./macos/embedded.sh if you need the ARM toolchain."
elif command -v arm-none-eabi-gcc >/dev/null 2>&1; then
    tc_ver="$(arm-none-eabi-gcc --version 2>&1 | head -n1)"
    doctor_pass "embedded-toolchain" "${tc_ver:-arm-none-eabi-gcc present, but produced no version output}"
else
    doctor_fail "embedded-toolchain" "arm-none-eabi-gcc shim exists but is not on PATH" \
        "Check that \$HOME/.local/bin is on PATH (see bashrc/.profile)."
fi
