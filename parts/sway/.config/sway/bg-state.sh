#!/bin/sh
# Runs on every (re)load. The config's background is the prepared login frame (so it is on screen the
# instant sway starts); once the session is up, put the real wallpaper back. During the startup splash
# (marker below) leave it alone: startup-reveal.sh restores the wallpaper itself at the reveal.
sleep 0.3
[ -e "$XDG_RUNTIME_DIR/startup/active" ] && exit 0
swaymsg output '*' bg "$HOME/.local/share/palette/wallpaper.png" fill >/dev/null
exit 0
