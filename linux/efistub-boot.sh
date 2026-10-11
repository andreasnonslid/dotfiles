#!/usr/bin/env bash
# Boot the kernel straight from UEFI (EFI stub): no GRUB, no menu. Needs Secure Boot OFF.
# Copies /vmlinuz + /initrd.img to the ESP and (re)creates a "Debian (direct)" boot entry
# first in BootOrder. The GRUB entry stays as fallback. Re-run after kernel updates.
# Usage: sudo linux/efistub-boot.sh [--hook]   (--hook also installs the kernel-update sync hooks)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
if [ "$(od -An -tu1 -j4 -N1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c)" -ne 0 ]; then
    echo "Secure Boot is on; an unsigned direct entry would not boot"; exit 1
fi
esp=/boot/efi
root=$(sed -n 's/.*\(root=[^ ]*\).*/\1/p' /proc/cmdline)
[ -n "$root" ] || { echo "no root= in /proc/cmdline"; exit 1; }
disk=$(lsblk -no PKNAME "$(findmnt -no SOURCE $esp)")
part=$(cat "/sys/class/block/$(basename "$(findmnt -no SOURCE $esp)")/partition")

install -d "$esp/EFI/linux"
cp -L /vmlinuz "$esp/EFI/linux/vmlinuz.efi.new"
cp -L /initrd.img "$esp/EFI/linux/initrd.img.new"
sync
mv "$esp/EFI/linux/vmlinuz.efi.new" "$esp/EFI/linux/vmlinuz.efi"
mv "$esp/EFI/linux/initrd.img.new" "$esp/EFI/linux/initrd.img"

label="Debian (direct)"
for n in $(efibootmgr | sed -n "s/^Boot\([0-9A-F]\{4\}\)\*\? $label\$/\1/p"); do
    efibootmgr -q -B -b "$n"
done
efibootmgr -q --create --disk "/dev/$disk" --part "$part" --label "$label" \
    --loader '\EFI\linux\vmlinuz.efi' \
    --unicode "$root ro quiet initrd=\\EFI\\linux\\initrd.img"
if [ "${1:-}" = "--hook" ]; then
    d=$(cd "$(dirname "$0")" && pwd)
    install -Dm755 "$d/efistub-sync" /etc/kernel/postinst.d/zz-efistub-sync
    install -Dm755 "$d/efistub-sync" /etc/initramfs/post-update.d/zz-efistub-sync
    echo "sync hooks installed"
fi
efibootmgr
