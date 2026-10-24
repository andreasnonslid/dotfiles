#!/usr/bin/env bash
# Clear a " [!]" tab suffix once that tab is focused. One process per session.
sess=$1
[ -n "$sess" ] || exit 0
pidfile=${XDG_CACHE_HOME:-$HOME/.cache}/zellij-bell-watch-$sess.pid
mkdir -p "$(dirname "$pidfile")"
if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
    exit 0
fi
echo $$ >"$pidfile"
trap 'rm -f "$pidfile"' EXIT
while true; do
    zellij --session "$sess" action dump-layout 2>/dev/null | python3 -c '
import sys, subprocess
sess = sys.argv[1]
for line in sys.stdin:
    s = line.strip()
    if s.startswith("tab name=") and "focus=true" in s:
        q = s.find("\"") + 1
        name = s[q:s.find("\"", q)]
        if name.endswith(" [!]"):
            base = name[:-4]
            n = base[5:] if base.startswith("Tab #") else ""
            if n.isdigit():
                subprocess.run(["zellij", "--session", sess, "pipe", "--name", "bell", "--", f"{n}\t{base}"], timeout=3)
' "$sess"
    sleep 0.4
done
