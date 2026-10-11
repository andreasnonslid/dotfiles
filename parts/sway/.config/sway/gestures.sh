#!/usr/bin/env bash
# lisgd touch gestures. $1 = number of 90-degree rotations (autorotate passes it).
# Needs read access to /dev/input (group `input`).
d=$(dirname "$0")
dev=
for n in /sys/class/input/event*/device/name; do
  [ "$(cat "$n")" = "ELAN2514:00 04F3:29DF" ] && dev=/dev/input/$(basename "$(dirname "$(dirname "$n")")")
done
[ -n "$dev" ] || exit 1
pkill -x lisgd
exec lisgd -d "$dev" -o "${1:-0}" \
  -g "1,DU,B,*,R,$d/osk-toggle.sh" \
  -g "2,UD,*,*,R,$d/osk-toggle.sh hide" \
  -g "1,LR,L,*,R,fuzzel" \
  -g "3,LR,*,*,R,swaymsg workspace prev" \
  -g "3,RL,*,*,R,swaymsg workspace next"
