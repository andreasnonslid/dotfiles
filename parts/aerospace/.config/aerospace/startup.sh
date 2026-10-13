#!/usr/bin/env bash
# AeroSpace after-startup: workspace 1 Ghostty, 2 Firefox, 3 Zed.
# Opens an app only when it has no window, then moves its windows once.
set -euo pipefail

if [[ -x /opt/homebrew/bin/aerospace ]]; then
    aero=/opt/homebrew/bin/aerospace
elif [[ -x /usr/local/bin/aerospace ]]; then
    aero=/usr/local/bin/aerospace
else
    exit 0
fi

place() {
    local bundle=$1 ws=$2 ids wid
    ids=$("$aero" list-windows --monitor all --app-bundle-id "$bundle" --format '%{window-id}' </dev/null || true)
    if [[ -z ${ids//[[:space:]]/} ]]; then
        /usr/bin/open -b "$bundle"
        local i
        for ((i = 0; i < 40; i++)); do
            ids=$("$aero" list-windows --monitor all --app-bundle-id "$bundle" --format '%{window-id}' </dev/null || true)
            [[ -n ${ids//[[:space:]]/} ]] && break
            sleep 0.25
        done
    fi
    while IFS= read -r wid; do
        [[ -n $wid ]] || continue
        "$aero" move-node-to-workspace --window-id "$wid" -- "$ws" </dev/null || true
    done <<<"$ids"
}

place com.mitchellh.ghostty 1
place org.mozilla.firefox 2
place dev.zed.Zed 3
"$aero" workspace 1 </dev/null || true
