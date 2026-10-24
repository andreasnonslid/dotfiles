#!/usr/bin/env bash
# Ring the pane bell. Zellij >= 0.44 shows [!] on an unfocused tab for that.
# 0.43 drops those bells, so a hidden plugin suffixes the tab name until it is focused.
p=$$
pty_pid=
while [ "$p" -gt 1 ]; do
    t=$(readlink "/proc/$p/fd/2" 2>/dev/null || true)
    case $t in
        /dev/pts/*)
            printf '\a' >"$t" 2>/dev/null || true
            pty_pid=$p
            break
            ;;
    esac
    p=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null) || exit 0
done
[ -n "$pty_pid" ] || exit 0
python3 - "$pty_pid" <<'PY'
import os, re, subprocess, sys
pid = sys.argv[1]
try:
    raw = open(f"/proc/{pid}/cmdline", "rb").read().replace(b"\0", b" ").decode()
    env = open(f"/proc/{pid}/environ", "rb").read().split(b"\0")
except OSError:
    sys.exit(0)
sess = next((e.split(b"=", 1)[1].decode() for e in env if e.startswith(b"ZELLIJ_SESSION_NAME=")), None)
if not sess:
    sys.exit(0)
watch = os.path.expanduser("~/dotfiles/scripts/zellij-bell-watch.sh")
subprocess.Popen([watch, sess], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
layout = subprocess.check_output(
    ["/usr/bin/zellij", "--session", sess, "action", "dump-layout"], text=True
)
tabs, cur = [], None
for line in layout.splitlines():
    s = line.strip()
    if s.startswith("tab name="):
        q = s.find('"')
        q2 = s.find('"', q + 1)
        cur = {"name": s[q + 1 : q2], "focus": "focus=true" in s, "panes": []}
        tabs.append(cur)
    elif cur is not None and s.startswith("pane command="):
        q = s.find('"')
        q2 = s.find('"', q + 1)
        cur["panes"].append([s[q + 1 : q2], []])
    elif cur is not None and cur["panes"] and s.startswith("args "):
        cur["panes"][-1][1] = s.split('"')[1::2]
hit, best = None, -1
for tab in tabs:
    for cmd, args in tab["panes"]:
        if cmd in raw and all(a in raw for a in args):
            score = len(cmd) + sum(map(len, args))
            if score > best:
                hit, best = tab, score
if not hit:
    sys.exit(0)
name = hit["name"]
base = name[:-4] if name.endswith(" [!]") else name
m = re.fullmatch(r"Tab #(\d+)", base)
if not m:
    sys.exit(0)
marked = f"{base} [!]"
if name == marked:
    sys.exit(0)
if hit["focus"]:
    sys.exit(0)
subprocess.run(
    ["/usr/bin/zellij", "--session", sess, "pipe", "--name", "bell", "--", f"{m.group(1)}\t{marked}"],
    timeout=3,
)
PY
