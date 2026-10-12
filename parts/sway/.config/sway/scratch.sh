#!/usr/bin/env bash
# Drop-down terminal: one key shows or hides a floating terminal (it keeps running in between).
# Created on first use; matched by app_id so it never touches your other terminals.
id=scratch-term
if ! swaymsg -t get_tree | grep -q "\"app_id\": \"$id\""; then
    setsid alacritty --class "$id" >/dev/null 2>&1 &
    for _ in $(seq 1 40); do
        swaymsg -t get_tree | grep -q "\"app_id\": \"$id\"" && break
        sleep 0.05
    done
fi
swaymsg "[app_id=\"$id\"] scratchpad show" >/dev/null
