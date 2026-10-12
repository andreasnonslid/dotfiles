#!/usr/bin/env bash
# Clipboard history picker: choose an earlier copy and it becomes the current clipboard again.
# History is recorded by `wl-paste --watch cliphist store` (started with sway).
command -v cliphist >/dev/null 2>&1 || { notify-send "Clipboard history" "cliphist is not installed"; exit 1; }
pick=$(cliphist list | fuzzel --dmenu --prompt "Clipboard  " --lines 12 --width 70) || exit 0
[ -n "$pick" ] || exit 0
printf '%s' "$pick" | cliphist decode | wl-copy
