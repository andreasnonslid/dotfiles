#!/usr/bin/env bash
# Install the palette-driven boot splash and turn the splash on (run: sudo linux/install-plymouth.sh).
# Regenerate first with `scripts/theme.py apply ...` after a colors change, then re-run this.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
d=$(cd "$(dirname "$0")" && pwd)
rm -rf /usr/share/plymouth/themes/dotfiles
cp -r "$d/plymouth/dotfiles" /usr/share/plymouth/themes/dotfiles
plymouth-set-default-theme -R dotfiles      # rebuilds the initramfs (sync hook copies it to the ESP)
"$d/efistub-boot.sh"                          # direct entry gets "quiet splash"
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub && ! grep -q 'splash' /etc/default/grub; then
    sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"|GRUB_CMDLINE_LINUX_DEFAULT="\1 splash"|' /etc/default/grub
    PATH=$PATH:/usr/sbin update-grub
fi
echo "boot splash installed. Revert: plymouth-set-default-theme -R $(plymouth-set-default-theme --list | grep -v dotfiles | head -1)"
