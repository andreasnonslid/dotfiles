#!/usr/bin/env bash
# Quick Bluetooth menu (waybar click): state, paired devices with connect/disconnect, scan/add, power.
# BT_DRY=1 prints the menu instead of showing it.
set -u
state=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')
connected=$(bluetoothctl devices Connected 2>/dev/null)
n_conn=$(printf '%s\n' "$connected" | grep -c '^Device')

lines=(); acts=()
add() { lines+=("$1"); acts+=("$2"); }

if [ "$state" = yes ]; then
    add "󰂯  Bluetooth on  ·  $n_conn connected" noop
    while read -r _ mac name; do
        [ -n "$mac" ] || continue
        if printf '%s\n' "$connected" | grep -q "$mac"; then
            add "󰂱  $name        connected  ·  disconnect" "disconnect $mac $name"
        else
            add "󰂯  $name        connect" "connect $mac $name"
        fi
    done < <(bluetoothctl devices Paired 2>/dev/null)
    add "󰂰  Scan / add a new device…" manager
    add "󰂲  Turn Bluetooth off" off
else
    add "󰂲  Bluetooth is off" noop
    add "󰂯  Turn Bluetooth on" on
fi

if [ -n "${BT_DRY:-}" ]; then printf '%s\n' "${lines[@]}"; exit 0; fi

pick=$(printf '%s\n' "${lines[@]}" | fuzzel --dmenu --index --prompt "Bluetooth  " --lines "${#lines[@]}" --width 52) || exit 0
[ -n "$pick" ] || exit 0
read -r verb mac name <<<"${acts[$pick]}"
case $verb in
    connect)    notify-send -t 2500 "Bluetooth" "Connecting to $name…"
                bluetoothctl connect "$mac" >/dev/null 2>&1 && notify-send -t 2500 "Bluetooth" "Connected: $name" \
                    || notify-send -t 4000 "Bluetooth" "Could not connect to $name" ;;
    disconnect) bluetoothctl disconnect "$mac" >/dev/null 2>&1; notify-send -t 2500 "Bluetooth" "Disconnected: $name" ;;
    manager)    exec blueman-manager ;;
    on)         bluetoothctl power on >/dev/null 2>&1 ;;
    off)        bluetoothctl power off >/dev/null 2>&1 ;;
esac
