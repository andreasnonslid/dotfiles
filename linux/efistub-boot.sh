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

install -d "$esp/EFI/debian-direct"
cp -L /vmlinuz "$esp/EFI/debian-direct/vmlinuz.efi.new"
cp -L /initrd.img "$esp/EFI/debian-direct/initrd.img.new"
sync
mv "$esp/EFI/debian-direct/vmlinuz.efi.new" "$esp/EFI/debian-direct/vmlinuz.efi"
mv "$esp/EFI/debian-direct/initrd.img.new" "$esp/EFI/debian-direct/initrd.img"

label="Debian (direct)"
for n in $(efibootmgr | sed -n "s/^Boot\([0-9A-F]\{4\}\)\*\? $label\$/\1/p"); do
    efibootmgr -q -B -b "$n"
done
# systemd-logind scans EFI/Linux for UKIs and logs an error per file, so we use another dir name.
[ -f "$esp/EFI/linux/vmlinuz.efi" ] && rm -rf "$esp/EFI/linux" || true
efibootmgr -q --create --disk "/dev/$disk" --part "$part" --label "$label" \
    --loader '\EFI\debian-direct\vmlinuz.efi' \
    --unicode "$root ro quiet splash loglevel=1 systemd.show_status=false rd.udev.log_level=3 udev.log_level=3 vt.global_cursor_default=0 initrd=\\EFI\\debian-direct\\initrd.img"
if [ "${1:-}" = "--hook" ]; then
    d=$(cd "$(dirname "$0")" && pwd)
    install -Dm755 "$d/efistub-sync" /etc/kernel/postinst.d/zz-efistub-sync
    install -Dm755 "$d/efistub-sync" /etc/initramfs/post-update.d/zz-efistub-sync
    echo "sync hooks installed"
fi
efibootmgr
