#!/usr/bin/env bash
# Session start. The password prompt IS the login: lock at once, then build the desktop behind it,
# so by the time the password is typed everything is already there. Timings: ~/.cache/startup.log
log=~/.cache/startup.log
t() { printf '%s %.3f\n' "$1" "$(date +%s.%N)"; }
touch "$XDG_RUNTIME_DIR/startup-active"      # keeps bg-state.sh from swapping the frame for the wallpaper
{ t script-start; echo "sway-uptime $(ps -o etimes= -p "$(pgrep -xn sway)")s"; } > "$log"

~/.config/sway/lock.sh
t locked >> "$log"

has_app() { swaymsg -t get_tree | grep -q "\"app_id\": \"$1\""; }
rm -f "$XDG_RUNTIME_DIR/waybar-ready"
has_app firefox-esr || { setsid firefox-esr >/dev/null 2>&1 & }
has_app dev.zed.Zed || { setsid ~/.local/bin/zed >/dev/null 2>&1 & }
pgrep -x waybar >/dev/null || NO_AT_BRIDGE=1 waybar -l info 2>> "$log" &
has_app Alacritty || alacritty &
t apps-launched >> "$log"

# Note when each piece is up (for scripts/startup-report.sh); nothing waits on this.
zed=; ff=; bar=; term=
for _ in $(seq 1 120); do
    tree=$(swaymsg -t get_tree)
    [ -z "$bar" ] && [ -e "$XDG_RUNTIME_DIR/waybar-ready" ] && { bar=1; t waybar-ready >> "$log"; }
    [ -z "$term" ] && grep -q '"app_id": "Alacritty"' <<<"$tree" && { term=1; t terminal-window >> "$log"; }
    [ -z "$zed" ] && grep -q '"app_id": "dev.zed.Zed"' <<<"$tree" && { zed=1; t zed-window >> "$log"; }
    [ -z "$ff" ] && grep -q '"app_id": "firefox-esr"' <<<"$tree" && { ff=1; t firefox-window >> "$log"; }
    [ -n "$bar$term$zed$ff" ] && [ "$bar$term$zed$ff" = 1111 ] && break
    sleep 0.25
done
t desktop-ready >> "$log"
wait
