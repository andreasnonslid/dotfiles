#!/usr/bin/env bash
# Region screenshot: select an area, save it, and copy it to the clipboard.
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

geometry="$(slurp)" || exit 0
grim -g "$geometry" "$FILE"
wl-copy <"$FILE"
notify-send -a "Hyprland" "Screenshot saved" "$FILE"
