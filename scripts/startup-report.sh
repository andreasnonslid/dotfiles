#!/usr/bin/env bash
# One-page report on the last boot + login: where the time went and what complained.
# Run after a reboot and login.  Usage: scripts/startup-report.sh
set -u
hr() { printf '\n== %s\n' "$1"; }

hr "boot (firmware / loader / kernel / userspace)"
systemd-analyze 2>/dev/null | head -1
printf 'kernel cmdline: %s\n' "$(cat /proc/cmdline)"

hr "login -> desktop (from ~/.cache/bar-handoff.log)"
log=~/.cache/bar-handoff.log
if [ -f "$log" ]; then
    grep -E '^(script-start|sway-uptime|waybar-launched|terminal-launched|ready|revealed|apps-launched|zed-window|firefox-window) ' "$log" |
    awk '
        $1=="script-start"{s=$2; print "script started"}
        $1=="sway-uptime"{print "sway had been up       " $2}
        $1=="waybar-launched"{printf "waybar launched       +%.2fs\n", $2-s}
        $1=="terminal-launched"{printf "terminal launched     +%.2fs\n", $2-s}
        $1=="ready"{printf "bar + terminal ready  +%.2fs\n", $2-s}
        $1=="revealed"{printf "cover lifted (revealed) +%.2fs   <- how long the wallpaper was held\n", $2-s}
        $1=="apps-launched"{printf "zed + firefox launched +%.2fs\n", $2-s}
        $1=="zed-window"{printf "zed window appeared    +%.2fs\n", $2-s}
        $1=="firefox-window"{printf "firefox window appeared +%.2fs\n", $2-s}'
    grep -E '^(some|full)' "$log" | head -2
else
    echo "no handoff log yet (log in with the Sway session first)"
fi

hr "services that failed"
systemctl --failed --no-pager --no-legend | sed 's/^/  /'; systemctl --user --failed --no-pager --no-legend | sed 's/^/  (user) /'

hr "warnings and errors this boot (known firmware noise filtered out)"
journalctl -b 0 -p warning --no-pager -o cat 2>/dev/null |
    grep -v -E 'ACPI|alsa-restore|hp_bioscfg|PCI INT|hpet_acpi|i8042|ENERGY_PERF|IMA_DISABLE|BAR5 too small|crc8|SGX|MMIO Stale|LE Coded|Parent card|HDMI converter|unchecked data|Not a switch|bitmask entry|hid_field_extract|No irq handler|IRQ triggered|ConfigurationDirectory|leaked proxy|xkbcomp|keycode|keysym|saved session|systemd1|gsd-|grab accelerator|UPower|a11y|Activating|Activated|Terminated|Xwayland terminated|Status Notifier|Found config|libcamera|gtk_widget_get_scale|discover_other|portal.IBus|pam_authenticate' |
    sed -E 's/[0-9]+/N/g' | sort | uniq -c | sort -rn | head -12

hr "boot-time hogs (top 6)"
systemd-analyze blame --no-pager 2>/dev/null | head -6 | sed 's/^/  /'

hr "wiring check"
for t in gtklock swaylock waybar keyd.rvaiya; do printf '  %-10s %s\n' "$t" "$(command -v "$t" >/dev/null 2>&1 && echo present || echo MISSING)"; done
systemctl is-active keyd >/dev/null 2>&1 && echo "  keyd active" || echo "  keyd NOT active"
pgrep -x swayidle >/dev/null && echo "  swayidle running" || echo "  swayidle NOT running"
pgrep -x waybar >/dev/null && echo "  waybar running" || echo "  waybar NOT running"
printf '  placeholder bar: %s\n' "$(swaymsg -t get_bar_config boot 2>/dev/null | grep -o '"mode": *"[a-z]*"' | head -1)"
