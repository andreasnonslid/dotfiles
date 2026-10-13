#!/usr/bin/env bash
# One-time root install of the page-cache pre-warm, with a cold vs pre-warmed measurement.
# Usage: sudo linux/install-prewarm.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || {
    echo "run with sudo"
    exit 1
}
d=$(cd "$(dirname "$0")" && pwd)

probe() { # time loading the desktop binaries' libraries (--version links them all)
    local s e
    s=$(date +%s.%N)
    for b in sway waybar swaylock alacritty mako fuzzel swaybg; do "/usr/bin/$b" --version >/dev/null 2>&1 || true; done
    e=$(date +%s.%N)
    printf '%.2f' "$(echo "$e - $s" | bc)"
}

echo "== measuring (drops the page cache once; harmless)"
sync
echo 3 >/proc/sys/vm/drop_caches
cold=$(probe)
sync
echo 3 >/proc/sys/vm/drop_caches
sh "$d/prewarm.sh"
warmed=$(probe)
echo "cold start of sway/waybar/etc libraries : ${cold}s"
echo "after pre-warm (same cache state else)  : ${warmed}s"

install -Dm755 "$d/prewarm.sh" /usr/local/libexec/dotfiles-prewarm
install -Dm644 "$d/dotfiles-prewarm.service" /etc/systemd/system/dotfiles-prewarm.service
systemctl daemon-reload
systemctl enable dotfiles-prewarm.service
echo "installed; runs at idle priority each boot. Remove: systemctl disable dotfiles-prewarm"
