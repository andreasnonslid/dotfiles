#!/usr/bin/env bash
# Pick a power profile from the situation: plugged in -> balanced; on battery -> balanced, but
# power-saver when the charge is low (<= LOW %). Re-checked every 30 s; only changes on a transition.
#   power-profile.sh          run forever (started by sway)
#   power-profile.sh --once   print the profile it would pick (POWER_AC=0|1 POWER_CAP=NN override sensors)
LOW=${LOW:-35}

ac_online() {
    [ -n "${POWER_AC:-}" ] && { echo "$POWER_AC"; return; }
    local f
    for f in /sys/class/power_supply/A{C,DP}*/online; do [ -r "$f" ] && { cat "$f"; return; }; done
    echo 1
}
capacity() {
    [ -n "${POWER_CAP:-}" ] && { echo "$POWER_CAP"; return; }
    cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100
}
desired() {
    if [ "$(ac_online)" = 1 ]; then echo balanced
    elif [ "$(capacity)" -le "$LOW" ]; then echo power-saver
    else echo balanced; fi
}

if [ "${1:-}" = "--once" ]; then desired; exit 0; fi

command -v powerprofilesctl >/dev/null 2>&1 || exit 0
last=
while true; do
    want=$(desired)
    if [ "$want" != "$last" ]; then
        powerprofilesctl set "$want" 2>/dev/null && last=$want
    fi
    sleep 30
done
