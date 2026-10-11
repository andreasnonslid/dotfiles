#!/bin/sh
# Lock the screen.
# swaylock aborts ("Unknown keymap format 0") while squeekboard's virtual keyboard, which has no
# keymap, is the seat's active keyboard. So: try once; if it aborts, stop squeekboard, lock, and
# bring squeekboard back as soon as the screen is unlocked.
pgrep -x swaylock >/dev/null && exit 0

try_lock() {
    swaylock -f
    sleep 0.5
    pgrep -x swaylock >/dev/null
}

try_lock && exit 0

pkill -x squeekboard
sleep 0.3
if try_lock; then
    ( while pgrep -x swaylock >/dev/null; do sleep 1; done; setsid squeekboard >/dev/null 2>&1 & ) >/dev/null 2>&1 &
    exit 0
fi
setsid squeekboard >/dev/null 2>&1 &
exit 1
