#!/usr/bin/env bash
# Start waybar, keep sway's placeholder bar until waybar has drawn, then hide the placeholder.
# Timings land in ~/.cache/bar-handoff.log (one session; overwritten at each login).
log=~/.cache/bar-handoff.log
t() { printf '%s %.3f\n' "$1" "$(date +%s.%N)"; }
{ t script-start; echo "sway-uptime $(ps -o etimes= -p "$(pgrep -xn sway)")s"; cat /proc/pressure/cpu; } > "$log" 2>&1
rm -f "$XDG_RUNTIME_DIR/waybar-ready"
# GTK would otherwise wait for the AT-SPI bus to be activated before drawing anything.
NO_AT_BRIDGE=1 waybar -l info 2>> "$log" &
t waybar-launched >> "$log"
for _ in $(seq 1 100); do
  [ -e "$XDG_RUNTIME_DIR/waybar-ready" ] && break
  sleep 0.05
done
t ready >> "$log"
sleep 0.15
swaymsg bar boot mode invisible >/dev/null
t placeholder-hidden >> "$log"
cat /proc/pressure/cpu >> "$log"
wait
