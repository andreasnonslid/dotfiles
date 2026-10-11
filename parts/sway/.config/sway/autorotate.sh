#!/usr/bin/env bash
# Rotate the screen (touch + pen follow via map_to_output) and gestures from the accelerometer.
out=eDP-1
dir=$(dirname "$0")
"$dir/gestures.sh" 0 &
monitor-sensor --accel | while read -r line; do
  case $line in
    *"orientation changed: normal"*)    t=normal; o=0 ;;
    *"orientation changed: bottom-up"*) t=180;    o=2 ;;
    *"orientation changed: right-up"*)  t=90;     o=1 ;;
    *"orientation changed: left-up"*)   t=270;    o=3 ;;
    *) continue ;;
  esac
  swaymsg output "$out" transform "$t" >/dev/null
  "$dir/gestures.sh" "$o" &
done
