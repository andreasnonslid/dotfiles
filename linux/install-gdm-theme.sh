#!/usr/bin/env bash
# One-time root install of the login-screen theming helper (run: sudo linux/install-gdm-theme.sh).
set -euo pipefail
u=${SUDO_USER:?run with sudo}
d=$(cd "$(dirname "$0")" && pwd)
install -Dm755 "$d/gdm-theme.py" /usr/local/libexec/dotfiles-gdm-theme
sed "s/USER/$u/g" "$d/dotfiles-gdm-theme.path" >/etc/systemd/system/dotfiles-gdm-theme.path
sed "s/USER/$u/g" "$d/dotfiles-gdm-theme.service" >/etc/systemd/system/dotfiles-gdm-theme.service
systemctl daemon-reload
systemctl enable --now dotfiles-gdm-theme.path
systemctl start dotfiles-gdm-theme.service || true # apply once now if input exists
echo "login theming installed; it follows $u's palette changes automatically"
