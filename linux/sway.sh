#!/usr/bin/env bash
# Sway desktop on Debian 13 (trixie): packages, keyd Caps=Esc/Hyper, font, wlr-which-key.
# Run after linux/debian.sh, then ./bootstrap.sh links parts/{sway,waybar,which-key,palette,alacritty}.
# Idempotent. Mirrors what was done by hand on the HP Spectre x360 (see ~/rice/log).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)

sudo apt-get update
sudo apt-get install -y \
    sway swaybg swaylock swayidle waybar fuzzel mako-notifier alacritty \
    squeekboard iio-sensor-proxy lisgd keyd brightnessctl playerctl \
    grim slurp wl-clipboard wev libnotify-bin xdg-desktop-portal-wlr \
    blueman network-manager-gnome pavucontrol lua5.4 wlsunset eza

# Touch gestures (lisgd) read /dev/input directly; takes effect on next login.
sudo usermod -aG input "$USER"

# Caps: tap = Esc, hold = Hyper (D4). Debian ships the binary as keyd.rvaiya.
sudo install -Dm644 "$root/linux/keyd.conf" /etc/keyd/default.conf
sudo systemctl enable keyd
sudo systemctl restart keyd

# Font (Nerd Font release, 4 faces only).
if ! fc-list | grep -q 'IosevkaTerm Nerd Font'; then
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/f.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.tar.xz
    mkdir -p ~/.local/share/fonts
    tar -xf "$tmp/f.tar.xz" -C ~/.local/share/fonts \
        IosevkaTermNerdFont-Regular.ttf IosevkaTermNerdFont-Bold.ttf \
        IosevkaTermNerdFont-Italic.ttf IosevkaTermNerdFont-BoldItalic.ttf
    rm -rf "$tmp"
    fc-cache -f
fi

# which-key overlay (not packaged).
if ! command -v wlr-which-key >/dev/null && [ ! -x "$HOME/.cargo/bin/wlr-which-key" ]; then
    "$HOME/.cargo/bin/cargo" install --locked wlr-which-key
fi

echo "Done. Log out and pick Sway at the login screen."
