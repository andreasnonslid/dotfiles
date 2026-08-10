#!/usr/bin/env bash
# scripts/doctor.d/40-toolchain.sh -- assumed binary + formatter presence (D03).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# Checks what's actually on PATH, not what a package manager thinks it
# installed -- same philosophy as 20-clipboard.sh and 30-homebrew.sh. Not
# darwin-specific: every one of these is already assumed by the Linux setup
# too (linux/*.sh installs the same tools under different package names).

# name:version-flag -- binaries every shell session assumes exist.
tc_binaries="
git:--version
nvim:--version
rg:--version
fd:--version
bat:--version
eza:--version
zoxide:--version
fzf:--version
jq:--version
just:--version
zellij:--version
starship:--version
gh:--version
mise:--version
lua:-v
"

# Formatters .githooks/pre-commit hard-requires via pretty.lua. lua is
# already checked above -- macos/Brewfile groups it in both sections for the
# same reason: it's genuine double duty, not an oversight.
tc_formatters="
shfmt:--version
stylua:--version
black:--version
taplo:--version
prettier:--version
clang-format:--version
"

tc_report_binary() {
    local tc_name="$1" tc_flag="$2" tc_ver
    if command -v "$tc_name" >/dev/null 2>&1; then
        tc_ver="$("$tc_name" "$tc_flag" 2>&1 | head -n1)"
        doctor_pass "$tc_name" "${tc_ver:-present, but produced no version output}"
    else
        doctor_fail "$tc_name" "not found on PATH" \
            "Install via macos/Brewfile (macOS) or linux/*.sh (Linux)."
    fi
}

while IFS=: read -r tc_name tc_flag; do
    [ -z "$tc_name" ] && continue
    tc_report_binary "$tc_name" "$tc_flag"
done <<<"$tc_binaries"

while IFS=: read -r tc_name tc_flag; do
    [ -z "$tc_name" ] && continue
    tc_report_binary "$tc_name" "$tc_flag"
done <<<"$tc_formatters"

# mise-pinned tool versions (M23): `mise current <tool>` resolves against
# ~/.config/mise/config.toml, but resolving is not the same as installed --
# if `mise install` was never run, it prints nothing instead of failing,
# and every python/node invocation silently falls through to whatever
# happens to be on PATH instead of the pinned version.
if command -v mise >/dev/null 2>&1; then
    for tc_mise_tool in python node; do
        tc_mise_ver="$(mise current "$tc_mise_tool" 2>/dev/null)"
        if [ -n "$tc_mise_ver" ]; then
            doctor_pass "mise-$tc_mise_tool" "active: $tc_mise_ver"
        else
            doctor_fail "mise-$tc_mise_tool" "no active version resolved" \
                "Run: mise install"
        fi
    done
else
    doctor_warn "mise-tools" "mise not installed, skipping version check" \
        "Install via macos/Brewfile, then run 'mise install'."
fi

# core.hooksPath: .githooks/pre-commit and commit-msg silently never run
# without this being set to .githooks (see scripts/setup-agent-env.sh).
# shellcheck disable=SC2154  # $root: set by scripts/doctor.sh before sourcing.
if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
    tc_hooks_path="$(git -C "$root" config --get core.hooksPath || true)"
    if [ "$tc_hooks_path" = ".githooks" ]; then
        doctor_pass "git-hooks" "core.hooksPath is .githooks"
    else
        doctor_fail "git-hooks" "core.hooksPath is '${tc_hooks_path:-<unset>}', not .githooks" \
            "Run: git -C '$root' config core.hooksPath .githooks"
    fi
else
    doctor_warn "git-hooks" "$root is not a git checkout" \
        "core.hooksPath can't be checked outside a git repo."
fi
