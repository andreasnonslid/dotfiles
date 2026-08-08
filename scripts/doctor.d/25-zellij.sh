#!/usr/bin/env bash
# scripts/doctor.d/25-zellij.sh -- zellij copy_command activation (M18).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# macos/install.sh activates `copy_command "pbcopy"` in config.kdl by
# uncommenting it in place (mirrors linux/arch.sh's pane_frames sed). This
# is exactly the kind of machine-state a real Mac could get wrong -- e.g.
# a manual edit re-commenting the line, or install.sh never having run --
# so it gets its own check rather than being assumed from the repo source.

if ! is_macos; then
    doctor_warn "zellij" "not macOS -- skipping copy_command check" \
        "This check only applies on darwin."
else
    config="$HOME/.config/zellij/config.kdl"
    if [ ! -f "$config" ]; then
        doctor_fail "zellij" "$config not found" \
            "Run ./bootstrap.sh to symlink it into place."
    elif grep -qE '^copy_command "pbcopy"' "$config"; then
        doctor_pass "zellij" "copy_command \"pbcopy\" active in config.kdl"
    else
        doctor_fail "zellij" "copy_command \"pbcopy\" not active in config.kdl" \
            "Run macos/install.sh, or uncomment 'copy_command \"pbcopy\"' by hand."
    fi
fi
