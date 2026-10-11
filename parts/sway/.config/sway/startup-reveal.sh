#!/usr/bin/env bash
# Hold the wallpaper on screen while waybar and the first terminal come up, then reveal them together.
# Timings: ~/.cache/bar-handoff.log (overwritten each login).
log=~/.cache/bar-handoff.log
t() { printf '%s %.3f\n' "$1" "$(date +%s.%N)"; }
{ t script-start; echo "sway-uptime $(ps -o etimes= -p "$(pgrep -xn sway)")s"; } > "$log"

# 1. Cover: swaylock with only the wallpaper (no ring). SIGUSR1 lifts it without a password.
#    The timeout guarantees the cover can never outlive a failed start.
if ! pgrep -x swaylock >/dev/null; then
  swaylock -f -u -s fill -i ~/.local/share/palette/wallpaper.png
  covered=1
fi
( sleep 8; pkill -USR1 -x swaylock ) &

# 2. Bar: waybar (idempotent), then wait until it reports it has built its modules.
rm -f "$XDG_RUNTIME_DIR/waybar-ready"
pgrep -x waybar >/dev/null || NO_AT_BRIDGE=1 waybar -l info 2>> "$log" &
t waybar-launched >> "$log"

# 3. Terminal on workspace 1, unless one is already there.
has_term() { swaymsg -t get_tree | grep -q '"app_id": "Alacritty"'; }
has_term || alacritty &
t terminal-launched >> "$log"

# 4. Wait for both (max ~6 s), let one frame settle, then reveal.
for _ in $(seq 1 120); do
  [ -e "$XDG_RUNTIME_DIR/waybar-ready" ] && has_term && break
  sleep 0.05
done
t ready >> "$log"
sleep 0.2
swaymsg bar boot mode invisible >/dev/null
[ -n "$covered" ] && pkill -USR1 -x swaylock
t revealed >> "$log"
wait
