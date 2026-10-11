#!/usr/bin/env bash
# Toggle (or `hide`) the squeekboard on-screen keyboard. Bottom-edge swipe up toggles, two-finger swipe down hides.
args=(--user sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0)
if [ "$1" = hide ]; then v=false
elif busctl get-property "${args[@]}" Visible | grep -q true; then v=false; else v=true; fi
busctl call "${args[@]}" SetVisible b $v
