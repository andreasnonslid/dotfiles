#!/usr/bin/env bash
# scripts/doctor.d/00-core.sh -- OS/arch, PATH sanity, $DOTFILES resolution.
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.

os="$(detect_os)"
arch="$(detect_arch)"

case "$os" in
darwin | linux)
    doctor_pass "os" "Detected OS: $os"
    ;;
windows)
    doctor_warn "os" "Detected OS: windows (Cygwin/MSYS, not WSL)" \
        "doctor.sh's checks mostly assume darwin or linux; some may not apply."
    ;;
*)
    doctor_fail "os" "Could not detect OS from 'uname -s' ($(uname -s))" \
        "This platform isn't one doctor.sh knows how to check."
    ;;
esac

doctor_pass "arch" "Detected arch: $arch"

# Rosetta / x86 emulation: only meaningful on Apple Silicon under Big Sur+.
# sysctl.proc_translated is absent on Intel Macs and on Linux -- that's the
# expected, non-error case, not something to report on.
if is_macos && command -v sysctl >/dev/null 2>&1; then
    translated="$(sysctl -in sysctl.proc_translated 2>/dev/null || true)"
    case "$translated" in
    1)
        doctor_warn "rosetta" "Running under Rosetta 2 (x86_64 emulation)" \
            "Re-launch this terminal natively (arm64) -- check 'Open using Rosetta' is off in Get Info."
        ;;
    0)
        doctor_pass "rosetta" "Running natively, no Rosetta emulation"
        ;;
    esac
fi

# PATH sanity: must be non-empty and contain only absolute entries. A
# relative entry is a real footgun (resolves differently depending on cwd).
if [ -z "${PATH:-}" ]; then
    doctor_fail "path" "\$PATH is empty" "Something is very wrong with this shell session."
else
    bad_entries=""
    old_ifs=$IFS
    IFS=:
    for entry in $PATH; do
        case "$entry" in
        /*) ;;
        *) bad_entries="${bad_entries}${bad_entries:+, }${entry:-<empty>}" ;;
        esac
    done
    IFS=$old_ifs

    if [ -n "$bad_entries" ]; then
        doctor_warn "path" "\$PATH has non-absolute entries: $bad_entries" \
            "Relative PATH entries resolve differently depending on the current directory."
    else
        doctor_pass "path" "\$PATH is non-empty with only absolute entries"
    fi
fi

# $DOTFILES resolution: bashrc/.bashrc and several tools/*.sh functions fall
# back to $HOME/dotfiles when $DOTFILES is unset, so that's the effective
# default this checks against too.
dotfiles_dir="${DOTFILES:-$HOME/dotfiles}"
if [ ! -d "$dotfiles_dir" ]; then
    doctor_fail "dotfiles" "\$DOTFILES does not resolve to a directory ($dotfiles_dir)" \
        "Clone the dotfiles repo to $dotfiles_dir, or export \$DOTFILES to its actual location."
elif ! git -C "$dotfiles_dir" rev-parse --git-dir >/dev/null 2>&1; then
    doctor_warn "dotfiles" "$dotfiles_dir exists but isn't a git checkout" \
        "Expected a clone of the dotfiles repo there."
else
    doctor_pass "dotfiles" "\$DOTFILES resolves to a git checkout: $dotfiles_dir"
fi
