#!/usr/bin/env bash
# Close the SSH exposure and stop services this laptop does not use. Fully reversible.
#   sudo linux/streamline.sh           apply
#   sudo linux/streamline.sh --revert  put it all back
#
#   ssh            : an SSH *server* listening on every interface with password logins allowed
#                    (outgoing ssh to other machines is unaffected)
#   cups, avahi    : printing and mDNS, with no printer configured
#   snap "just"    : replaced by the apt package (snapd itself stays: obsidian still needs it)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
units_ssh="ssh.service ssh.socket"
units_print="cups.service cups.socket cups.path cups-browsed.service avahi-daemon.service avahi-daemon.socket"

have() { systemctl list-unit-files --no-legend "$1" 2>/dev/null | grep -q .; }

if [ "${1:-}" = "--revert" ]; then
    for u in $units_ssh $units_print; do have "$u" && systemctl enable --now "$u" 2>/dev/null || true; done
    echo "reverted: ssh, cups and avahi are enabled again"
    exit 0
fi

echo "== before: listening sockets"
ss -tulnH | awk '{print "   " $1, $5}' | sort -u | head -12

for u in $units_ssh $units_print; do
    if have "$u"; then
        systemctl disable --now "$u" 2>/dev/null && echo "   stopped+disabled $u" || echo "   (could not stop $u)"
    fi
done

# just: apt instead of the snap (same tool, no snapd round trip at every start)
if snap list just >/dev/null 2>&1; then
    apt-get install -y just >/dev/null 2>&1 && snap remove just >/dev/null 2>&1 && echo "   just: snap -> apt ($(command -v just))"
fi

echo "== after: listening sockets"
ss -tulnH | awk '{print "   " $1, $5}' | sort -u | head -12
