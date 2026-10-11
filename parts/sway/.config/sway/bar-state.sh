#!/bin/sh
# Runs on every (re)load: if waybar is already up, the placeholder bar must stay hidden.
pgrep -x waybar >/dev/null && swaymsg bar boot mode invisible >/dev/null
exit 0
