#!/usr/bin/env bash
# Let the lock-screen password unlock the login keyring.
# Autologin has no password, so the keyring stays locked until something supplies it; the lock screen
# does. The module only USES the password the stack already collected; as "optional" it can never make
# an unlock fail. Idempotent, with a backup.
#   sudo linux/install-lock-keyring.sh          add
#   sudo linux/install-lock-keyring.sh --off    remove again
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
line='auth optional pam_gnome_keyring.so'
for f in /etc/pam.d/gtklock /etc/pam.d/swaylock; do
    [ -f "$f" ] || continue
    cp -a "$f" "$f.pre-keyring" 2>/dev/null || true
    sed -i '\|^auth optional pam_gnome_keyring.so$|d' "$f"
    if [ "${1:-}" != "--off" ]; then
        printf '%s\n' "$line" >> "$f"
    fi
    echo "== $f"; cat "$f"
done
