#!/usr/bin/env bash
# scripts/doctor.d/20-clipboard.sh -- clip/paste tool availability (M09).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# tools/clipboard.sh's clip/paste dispatch at call time, not install time,
# so this mirrors that: it checks whichever tool the *current* session
# would actually reach for, not every tool that could theoretically exist.

if is_macos; then
    if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
        doctor_pass "clipboard" "pbcopy/pbpaste available"
    else
        doctor_fail "clipboard" "pbcopy/pbpaste missing" \
            "These ship with macOS; something is unusually broken."
    fi
elif is_wsl; then
    if command -v clip.exe >/dev/null 2>&1; then
        doctor_pass "clipboard" "clip.exe available for clip"
    else
        doctor_fail "clipboard" "clip.exe not on PATH" \
            "Expected via the Windows PATH passthrough -- check \$PATH includes /mnt/c/Windows/System32."
    fi
    if command -v powershell.exe >/dev/null 2>&1; then
        doctor_pass "clipboard" "powershell.exe available for paste"
    else
        doctor_warn "clipboard" "powershell.exe not on PATH" \
            "paste falls back to Get-Clipboard via powershell.exe; clip (copy) still works without it."
    fi
elif [ -n "${WAYLAND_DISPLAY:-}" ]; then
    if command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
        doctor_pass "clipboard" "wl-copy/wl-paste available (Wayland session)"
    else
        doctor_fail "clipboard" "wl-copy/wl-paste missing (Wayland session)" "Install wl-clipboard."
    fi
elif [ -n "${DISPLAY:-}" ]; then
    if command -v xclip >/dev/null 2>&1; then
        doctor_pass "clipboard" "xclip available (X11 session)"
    else
        doctor_fail "clipboard" "xclip missing (X11 session)" "Install xclip."
    fi
else
    doctor_warn "clipboard" "no graphical session detected (no \$WAYLAND_DISPLAY or \$DISPLAY)" \
        "Expected on a headless machine/SSH session without X forwarding; clip/paste will fail if called here."
fi
