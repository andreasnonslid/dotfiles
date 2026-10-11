#!/bin/sh
# Runs on every (re)load. The config's background is the lock frame (on screen the instant sway starts);
# once the session is unlocked, the real wallpaper goes back. While locked, or during startup, leave it.
sleep 0.3
[ -e "$XDG_RUNTIME_DIR/startup-active" ] && exit 0
pgrep -x gtklock >/dev/null && exit 0
pgrep -x swaylock >/dev/null && exit 0
swaymsg output '*' bg "$HOME/.local/share/palette/wallpaper.png" fill >/dev/null
exit 0
