#!/usr/bin/env bash
# scripts/doctor.d/30-homebrew.sh -- Xcode CLT + Homebrew presence (M13).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# Only meaningful on macOS -- macos/install.sh is the only thing that
# provisions either of these. D06 (needs-mac) later extends this section
# with brew bundle satisfaction and cask-specific checks.

if ! is_macos; then
    doctor_warn "homebrew" "not macOS -- skipping Xcode CLT / Homebrew checks" \
        "This section only applies on darwin."
else
    if xcode-select -p >/dev/null 2>&1; then
        doctor_pass "homebrew" "Xcode Command Line Tools installed"
    else
        doctor_fail "homebrew" "Xcode Command Line Tools not installed" \
            "Run macos/install.sh, or 'xcode-select --install' directly."
    fi

    case "$(detect_arch)" in
    arm64) brew_prefix=/opt/homebrew ;;
    *) brew_prefix=/usr/local ;;
    esac

    if [ -x "$brew_prefix/bin/brew" ]; then
        brew_version="$("$brew_prefix/bin/brew" --version 2>/dev/null | head -n1)"
        doctor_pass "homebrew" "Homebrew installed at $brew_prefix ($brew_version)"
    else
        doctor_fail "homebrew" "Homebrew not found at $brew_prefix" \
            "Run macos/install.sh, or install Homebrew directly."
    fi
fi
