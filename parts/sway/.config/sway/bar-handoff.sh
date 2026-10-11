#!/usr/bin/env bash
# Start waybar, keep sway's placeholder bar until waybar has drawn, then hide the placeholder.
rm -f "$XDG_RUNTIME_DIR/waybar-ready"
waybar &
for _ in $(seq 1 100); do
  [ -e "$XDG_RUNTIME_DIR/waybar-ready" ] && break
  sleep 0.1
done
sleep 0.3
swaymsg bar boot mode invisible >/dev/null
wait
