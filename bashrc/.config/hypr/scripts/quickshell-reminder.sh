#!/usr/bin/env bash
# Fires once, on the first Hyprland startup after the target date/time.
# Set up 2026-07-03 as a nudge to revisit quickshell/AGS for a custom shell.

set -euo pipefail

THRESHOLD="2026-07-31 16:00"
MARKER_DIR="$HOME/.local/state/hypr"
MARKER="$MARKER_DIR/quickshell-reminder-done"

mkdir -p "$MARKER_DIR"

[ -f "$MARKER" ] && exit 0

now_epoch=$(date +%s)
threshold_epoch=$(date -d "$THRESHOLD" +%s)

if [ "$now_epoch" -ge "$threshold_epoch" ]; then
    notify-send -u critical -a "Hyprland" "Quickshell reminder" \
        "It's been 4 weeks — take a look at quickshell/AGS for a custom shell now that you're settled into Hyprland."
    xdg-open "https://quickshell.org/" >/dev/null 2>&1 &
    touch "$MARKER"
fi
