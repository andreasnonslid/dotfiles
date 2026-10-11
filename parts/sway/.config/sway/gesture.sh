#!/usr/bin/env bash
# Touchpad 3-finger gestures (bound in config with bindgesture).
#   left / right : next / previous workspace; left on the last one opens a fresh empty workspace
#   up           : overview, a picker of every open and minimized window (fuzzel)
#   down         : close the overview; otherwise minimize all windows of this workspace,
#                  and if they are all minimized already, bring them back
action=${1:?left|right|up|down}
state=${XDG_RUNTIME_DIR:-/tmp}/minimized
mkdir -p "$state"

LEAVES='def leaves(w): if ((.nodes|length)==0 and (.floating_nodes|length)==0 and .pid != null)
  then [. + {ws: w}]
  else ([.nodes[]?, .floating_nodes[]?] | map(leaves(w)) | add // []) end;
  [.nodes[] | .nodes[]? | select(.type=="workspace") | . as $w | leaves($w.name)[]]'

overview_open() { pgrep -f 'fuzzel.*--prompt.*Windows' >/dev/null; }
cur_ws() { swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name'; }

case $action in
left | right)
    cur=$(cur_ws)
    nums=$(swaymsg -t get_workspaces | jq -r '.[].name' | grep -E '^[0-9]+$' | sort -n)
    [[ $cur =~ ^[0-9]+$ ]] || exit 0
    if [ "$action" = left ]; then
        nxt=$(echo "$nums" | awk -v c="$cur" '$1>c{print $1; exit}')
        if [ -z "$nxt" ]; then
            # last workspace: only open a new one if this one is not empty
            has=$(swaymsg -t get_tree | jq -r --arg w "$cur" "$LEAVES | map(select(.ws==\$w)) | length")
            [ "${has:-0}" -gt 0 ] && nxt=$((cur + 1))
        fi
    else
        nxt=$(echo "$nums" | awk -v c="$cur" '$1<c{p=$1} END{if(p)print p}')
    fi
    [ -n "${nxt:-}" ] && swaymsg workspace number "$nxt" >/dev/null
    ;;
up)
    overview_open && exit 0
    tree=$(swaymsg -t get_tree)
    rows=$(echo "$tree" | jq -c "$LEAVES | map({id, ws, app: (.app_id // .window_properties.class // \"?\"), title: .name})")
    n=$(echo "$rows" | jq length)
    [ "$n" -gt 0 ] || exit 0
    lines=$(echo "$rows" | jq -r '.[] | (if .ws=="__i3_scratch" then "󰘸 minimized" else "󰖲 " + .ws end) + "   " + .app + "   " + (.title // "")')
    pick=$(printf '%s\n' "$lines" | fuzzel --dmenu --index --prompt "Windows  " --lines "$(( n > 10 ? 10 : n ))" --width 60) || exit 0
    [ -n "$pick" ] || exit 0
    id=$(echo "$rows" | jq -r ".[$pick].id")
    ws=$(echo "$rows" | jq -r ".[$pick].ws")
    if [ "$ws" = "__i3_scratch" ]; then
        swaymsg "[con_id=$id] scratchpad show, floating disable" >/dev/null
    else
        swaymsg "[con_id=$id] focus" >/dev/null
    fi
    ;;
down)
    if overview_open; then pkill -f 'fuzzel.*--prompt.*Windows'; exit 0; fi
    ws=$(cur_ws)
    f="$state/$(printf '%s' "$ws" | tr -c 'A-Za-z0-9' _)"
    ids=$(swaymsg -t get_tree | jq -r --arg w "$ws" "$LEAVES | map(select(.ws==\$w)) | .[].id")
    if [ -n "$ids" ]; then
        printf '%s\n' $ids > "$f"
        for id in $ids; do swaymsg "[con_id=$id] move scratchpad" >/dev/null; done
    elif [ -s "$f" ]; then
        while read -r id; do
            swaymsg "[con_id=$id] scratchpad show, floating disable" >/dev/null
        done < "$f"
        rm -f "$f"
    fi
    ;;
esac
