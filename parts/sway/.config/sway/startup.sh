#!/usr/bin/env bash
# Session start. The password prompt IS the login: lock at once, then build the desktop behind it,
# so by the time the password is typed everything is already there. Timings: ~/.cache/startup.log
log=~/.cache/startup.log
t() { printf '%s %.3f\n' "$1" "$(date +%s.%N)"; }
# GDM only lets the boot splash quit when a GNOME session says it is ready, which sway never does, so it
# waits ~20 s and holds up graphical.target. Say it ourselves (harmless if it is already gone).
command -v plymouth >/dev/null 2>&1 && { plymouth quit --retain-splash >/dev/null 2>&1 & }
touch "$XDG_RUNTIME_DIR/startup-active"      # keeps bg-state.sh from swapping the frame for the wallpaper
{ t script-start; echo "sway-uptime $(ps -o etimes= -p "$(pgrep -xn sway)")s"; } > "$log"

# Only an automatic login needs the lock screen (it IS the login then). After a normal GDM login you
# have already typed your password, so locking again would just ask for it twice.
should_lock() {
    conf=${GDM_CONF:-/etc/gdm3/daemon.conf}
    grep -qs '^AutomaticLoginEnable *= *true' "$conf" || return 1
    grep -qs "^AutomaticLogin *= *$USER" "$conf" || return 1
    up=${STARTUP_UPTIME:-$(cut -d. -f1 /proc/uptime)}
    [ "$up" -lt 240 ]            # autologin only happens right after power-on
}
if should_lock; then
    ~/.config/sway/lock.sh
    t locked >> "$log"
else
    rm -f "$XDG_RUNTIME_DIR/startup-active"    # no lock to hold the frame for: the wallpaper may return
    t lock-skipped >> "$log"
fi

has_app() { swaymsg -t get_tree | grep -q "\"app_id\": \"$1\""; }
rm -f "$XDG_RUNTIME_DIR/waybar-ready"
has_app firefox-esr || { setsid firefox-esr >/dev/null 2>&1 & }
has_app dev.zed.Zed || { setsid ~/.local/bin/zed >/dev/null 2>&1 & }
pgrep -x waybar >/dev/null || NO_AT_BRIDGE=1 waybar -l info 2>> "$log" &
has_app Alacritty || alacritty &
t apps-launched >> "$log"

# Note when each piece is up (for scripts/startup-report.sh); nothing waits on this.
zed=; ff=; bar=; term=
for _ in $(seq 1 "${STARTUP_POLLS:-120}"); do
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
