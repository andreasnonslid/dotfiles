#!/usr/bin/env bash
# scripts/doctor.d/27-ssh.sh -- tracked ssh config integrity (M30).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# ~/.ssh/config is tracked (bashrc/.ssh/config) and pulls in per-host
# secrets via `Include ~/.local/secrets/ssh/*.conf`, plus a darwin-only
# `Include ~/.ssh/config.darwin` for the one keyword (UseKeychain) that a
# non-Apple OpenSSH build refuses to parse. 10-symlinks.sh already confirms
# the links themselves exist and resolve into the repo; this checks the
# things that only show up once ssh actually reads the file -- permissions
# it will refuse to use, and syntax errors an Include target could
# introduce.

section="ssh"

ssh_dir="$HOME/.ssh"
config="$ssh_dir/config"

if [ -d "$ssh_dir" ]; then
    mode="$(stat -c '%a' "$ssh_dir" 2>/dev/null || stat -f '%Lp' "$ssh_dir" 2>/dev/null)"
    if [ "$mode" = "700" ]; then
        doctor_pass "$section" "$ssh_dir is 700"
    else
        doctor_warn "$section" "$ssh_dir is $mode, not 700" \
            "ssh silently ignores keys it considers too permissive -- run 'chmod 700 $ssh_dir'."
    fi
else
    doctor_warn "$section" "$ssh_dir does not exist" \
        "Bootstrap didn't run, or ran partially -- run ./bootstrap.sh."
fi

if ! command -v ssh >/dev/null 2>&1; then
    doctor_fail "$section" "ssh not found" "Expected to ship with the OS; something is unusually broken."
elif [ ! -e "$config" ]; then
    doctor_warn "$section" "$config missing" \
        "Bootstrap didn't run, or ran partially -- run ./bootstrap.sh."
elif ssh -G -F "$config" doctor-ssh-config-probe.invalid >/dev/null 2>&1; then
    doctor_pass "$section" "$config (plus any Include targets) parses cleanly"
else
    doctor_fail "$section" "$config fails to parse" \
        "Run 'ssh -G -F $config doctor-ssh-config-probe.invalid' to see the syntax error -- check \$HOME/.local/secrets/ssh/*.conf and, on macOS, that config.darwin is the linked M30 template."
fi

if is_macos && [ ! -e "$ssh_dir/config.darwin" ]; then
    doctor_warn "$section" "$ssh_dir/config.darwin missing on macOS" \
        "UseKeychain (M30) won't apply -- re-run ./bootstrap.sh so symlink.py links it in."
fi

secrets_ssh_dir="$HOME/.local/secrets/ssh"
if [ -d "$secrets_ssh_dir" ]; then
    secrets_mode="$(stat -c '%a' "$secrets_ssh_dir" 2>/dev/null || stat -f '%Lp' "$secrets_ssh_dir" 2>/dev/null)"
    if [ "$secrets_mode" = "700" ]; then
        doctor_pass "$section" "$secrets_ssh_dir is 700"
    else
        doctor_warn "$section" "$secrets_ssh_dir is $secrets_mode, not 700" \
            "Run 'chmod 700 $secrets_ssh_dir' -- ssh/setup_git_host.sh sets this itself when it creates the directory."
    fi
else
    doctor_pass "$section" "$secrets_ssh_dir not present (no per-host entries added yet)"
fi
