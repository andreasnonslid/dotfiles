#!/usr/bin/env bash
# Picks a random image from WALLPAPER_DIR and sets it via hyprpaper's IPC.
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f -iregex '.*\.\(jpg\|jpeg\|png\|webp\)')

if [ "${#images[@]}" -eq 0 ]; then
    echo "No images found in $WALLPAPER_DIR" >&2
    exit 1
fi

pick="${images[RANDOM % ${#images[@]}]}"

set_wallpaper() {
    # hyprpaper may have just been launched by autostart; retry until its IPC is up.
    for _ in $(seq 1 20); do
        hyprctl hyprpaper wallpaper "$1,$pick" >/dev/null 2>&1 && return 0
        sleep 0.25
    done
    return 1
}

for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
    set_wallpaper "$monitor"
done
