#!/bin/sh
# Lock the screen (idle, sleep, Super+L, the leader menu, and at session start: the password
# prompt is the login). Prefers gtklock; swaylock is the fallback.
#
# After every unlock: the real wallpaper goes back behind the windows and the next quote is prepared.
# swaylock aborts ("Unknown keymap format 0") while squeekboard's virtual keyboard, which has no keymap,
# is the seat's active keyboard: if that happens, stop squeekboard, lock, and bring it back after.
pgrep -x gtklock >/dev/null && exit 0
pgrep -x swaylock >/dev/null && exit 0

after_unlock() {
    ( while pgrep -x gtklock >/dev/null || pgrep -x swaylock >/dev/null; do sleep 0.4; done
      rm -f "$XDG_RUNTIME_DIR/startup-active"
      swaymsg output '*' bg "$HOME/.local/share/palette/wallpaper.png" fill >/dev/null 2>&1
      pgrep -x squeekboard >/dev/null || setsid squeekboard >/dev/null 2>&1 &
      python3 "$HOME/.config/sway/quote-frame.py" --render "$HOME/.local/share/palette/lock-frame.png" --new
    ) >/dev/null 2>&1 &
}

if command -v gtklock >/dev/null 2>&1; then
    gtklock -d
    sleep 0.5
    if pgrep -x gtklock >/dev/null; then after_unlock; exit 0; fi
fi

try_lock() {
    swaylock -f
    sleep 0.5
    pgrep -x swaylock >/dev/null
}

if try_lock; then after_unlock; exit 0; fi

pkill -x squeekboard
sleep 0.3
if try_lock; then after_unlock; exit 0; fi
setsid squeekboard >/dev/null 2>&1 &
exit 1
