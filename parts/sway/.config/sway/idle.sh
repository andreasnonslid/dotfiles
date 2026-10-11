#!/bin/sh
# (Re)start swayidle. Run via exec_always so a sway reload picks up changes here;
# a swayidle started at login would otherwise keep running its old commands.
pkill -x swayidle
exec swayidle -w \
    timeout 300 "$HOME/.config/sway/lock.sh" \
    timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    timeout 900 'systemctl suspend' \
    before-sleep "$HOME/.config/sway/lock.sh"
