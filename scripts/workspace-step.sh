#!/usr/bin/env bash
# next|prev through numbered workspaces that have windows, plus one empty
# workspace after the last of those. The sequence wraps:
#   1, 2, …, last-with-windows, empty, back to 1.
# From 1, prev lands on that empty workspace. From the empty one, prev
# lands on the last workspace that has windows.
set -euo pipefail

dir=${1:?next|prev}
[[ $dir == next || $dir == prev ]] || exit 2

# LaunchAgents start with PATH=/usr/bin:/bin, so Homebrew tools are missed.
resolve() {
    if command -v "$1" >/dev/null 2>&1; then
        command -v "$1"
        return
    fi
    local dir
    for dir in /opt/homebrew/bin /usr/local/bin "${HOME}/.local/bin"; do
        if [[ -x ${dir}/$1 ]]; then
            echo "${dir}/$1"
            return
        fi
    done
    return 1
}

if [[ -n ${SWAYSOCK:-} ]] && sway=$(resolve swaymsg) && jq=$(resolve jq); then
    backend=sway
elif aero=$(resolve aerospace); then
    backend=aerospace
else
    echo "workspace-step: aerospace and swaymsg not found" >&2
    exit 1
fi

if [[ $backend == sway ]]; then
    cur=$("$sway" -t get_workspaces | "$jq" -r '.[] | select(.focused) | .name')
    occupied=$("$sway" -t get_tree | "$jq" -r '
      def leaves(w):
        if ((.nodes|length)==0 and (.floating_nodes|length)==0 and .pid != null)
        then [. + {ws: w}]
        else ([.nodes[]?, .floating_nodes[]?] | map(leaves(w)) | add // []) end;
      [.nodes[] | .nodes[]? | select(.type=="workspace") | . as $w | leaves($w.name)[]]
      | [.[].ws | select(test("^[0-9]+$"))]
      | unique_by(tonumber) | sort_by(tonumber) | .[]
    ')
else
    cur=$("$aero" list-workspaces --focused | tr -d '[:space:]')
    occupied=$("$aero" list-workspaces --monitor all --empty no)
fi

[[ $cur =~ ^[0-9]+$ ]] || exit 0

ring=()
max=0
while IFS= read -r n; do
    [[ $n =~ ^[0-9]+$ ]] || continue
    ring+=("$n")
    if ((n > max)); then
        max=$n
    fi
done <<<"$occupied"

if ((${#ring[@]} == 0)); then
    spare=1
else
    spare=$((max + 1))
fi
ring+=("$spare")

idx=-1
for i in "${!ring[@]}"; do
    if [[ ${ring[$i]} == "$cur" ]]; then
        idx=$i
        break
    fi
done

count=${#ring[@]}
if ((idx >= 0)); then
    if [[ $dir == next ]]; then
        target=${ring[$(((idx + 1) % count))]}
    else
        target=${ring[$(((idx - 1 + count) % count))]}
    fi
elif [[ $dir == next ]]; then
    target=${ring[0]}
    for w in "${ring[@]}"; do
        if ((w > cur)); then
            target=$w
            break
        fi
    done
else
    target=${ring[$((count - 1))]}
    for w in "${ring[@]}"; do
        if ((w < cur)); then
            target=$w
        fi
    done
fi

[[ $target == "$cur" ]] && exit 0

if [[ $backend == sway ]]; then
    "$sway" workspace number "$target" >/dev/null
else
    "$aero" workspace "$target" >/dev/null
fi
