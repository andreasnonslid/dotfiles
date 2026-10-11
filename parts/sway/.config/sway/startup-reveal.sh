#!/usr/bin/env bash
# Hold a quote splash on screen while the bar, a terminal, Zed and Firefox come up, then reveal them together.
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

# 1b. The splash (quote + quiet progress) takes over from the plain cover once it is on screen.
#     If it cannot start, the cover simply stays until the reveal below.
RUN="$XDG_RUNTIME_DIR/startup"
rm -rf "$RUN"; mkdir -p "$RUN"
has_app() { swaymsg -t get_tree | grep -q "\"app_id\": \"$1\""; }
python3 ~/.config/sway/startup-splash.py >/dev/null 2>&1 &
splash_pid=$!
for _ in $(seq 1 40); do has_app startup-splash && break; sleep 0.05; done
if has_app startup-splash; then
    [ -n "$covered" ] && pkill -USR1 -x swaylock
    covered=
fi
t splash-up >> "$log"

# 2. Launch everything up front, in parallel, slowest first: Firefox and Zed (assigned to
#    workspaces 3 and 2 by the sway config), the bar, and the terminal.
rm -f "$XDG_RUNTIME_DIR/waybar-ready"
has_app firefox-esr || { setsid firefox-esr >/dev/null 2>&1 & }
has_app dev.zed.Zed || { setsid ~/.local/bin/zed >/dev/null 2>&1 & }
t apps-launched >> "$log"
pgrep -x waybar >/dev/null || NO_AT_BRIDGE=1 waybar -l info 2>> "$log" &
t waybar-launched >> "$log"
has_app Alacritty || alacritty &
t terminal-launched >> "$log"

# 3. Hold the cover until the bar, the terminal and both apps have a window (cap: HOLD_MAX seconds),
#    so workspaces 2 and 3 are already there when you switch to them. Set HOLD_MAX=1 for a short hold.
HOLD_MAX=${HOLD_MAX:-6}
zed=; ff=; bar=; term=
for _ in $(seq 1 $((HOLD_MAX * 20))); do
    tree=$(swaymsg -t get_tree)
    [ -z "$zed" ] && grep -q '"app_id": "dev.zed.Zed"' <<<"$tree" && { zed=1; touch "$RUN/zed"; t zed-window >> "$log"; }
    [ -z "$ff" ] && grep -q '"app_id": "firefox-esr"' <<<"$tree" && { ff=1; touch "$RUN/firefox"; t firefox-window >> "$log"; }
    [ -z "$bar" ] && [ -e "$XDG_RUNTIME_DIR/waybar-ready" ] && { bar=1; touch "$RUN/waybar"; }
    [ -z "$term" ] && grep -q '"app_id": "Alacritty"' <<<"$tree" && { term=1; touch "$RUN/terminal"; }
    [ -n "$bar" ] && [ -n "$term" ] && [ -n "$zed" ] && [ -n "$ff" ] && break
    sleep 0.05
done
t ready >> "$log"
sleep 0.25   # let the last windows paint a first frame
touch "$RUN/done"
for _ in $(seq 1 30); do kill -0 "$splash_pid" 2>/dev/null || break; sleep 0.05; done
kill "$splash_pid" 2>/dev/null          # never leave it behind
swaymsg bar boot mode invisible >/dev/null
[ -n "$covered" ] && pkill -USR1 -x swaylock
t revealed >> "$log"
wait
