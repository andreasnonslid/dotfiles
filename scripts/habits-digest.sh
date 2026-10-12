#!/usr/bin/env bash
# Once a week (and only with enough data), show a short notification about your habits.
# Called a little after you unlock the screen; does nothing the rest of the time.
log=${XDG_DATA_HOME:-$HOME/.local/share}/habits/commands.tsv
stamp=${XDG_DATA_HOME:-$HOME/.local/share}/habits/digest.stamp
here=$(cd "$(dirname "$0")" && pwd)
now=$(date +%s)

[ -s "$log" ] || exit 0
# at least 3 days of data, and not more often than every 7 days
first=$(head -1 "$log" | cut -f1)
[ $(( now - first )) -ge $(( 3 * 86400 )) ] || exit 0
[ -f "$stamp" ] && [ $(( now - $(cat "$stamp") )) -lt $(( 7 * 86400 )) ] && exit 0

text=$(python3 "$here/habits.py" --digest) || exit 0
[ -n "$text" ] || exit 0
notify-send -t 15000 "Your week in the terminal" "$text"
echo "$now" > "$stamp"
