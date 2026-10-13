#!/usr/bin/env bash
# Deterministic test of the session start: runs the REAL startup.sh / lock.sh / bg-state.sh against
# stand-in programs in a sandbox (own HOME, own runtime dir, own fake pgrep/pkill/swaymsg), so it
# never touches the screen or any real process.   Usage: tests/startup_test.sh
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
src=$here/parts/sway/.config/sway
T=$(mktemp -d)
[ -n "${KEEP:-}" ] && echo "sandbox: $T" || trap 'pkill -f "$T/" 2>/dev/null; rm -rf "$T"' EXIT
fail=0
ok() { printf '  ok    %s\n' "$1"; }
bad() {
    printf '  FAIL  %s\n' "$1"
    fail=1
}
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# ---- 0. static: everything the sway config runs exists, and runs
echo "static checks"
cfg=$src/config
while read -r path; do
    f=$src/${path##*/}
    [ -e "$f" ] || {
        bad "referenced but missing: $path"
        continue
    }
    # scripts started with an explicit interpreter ("bash path") need no exec bit
    if grep -qE "^(exec|exec_always) +(bash|sh|python3) +$path" "$cfg"; then
        ok "runs via interpreter: ${path##*/}"
    elif [ -x "$f" ]; then
        ok "executable: ${path##*/}"
    else bad "NOT EXECUTABLE (sway would silently skip it): ${path##*/}"; fi
done < <(grep -oE '~/\.config/sway/[A-Za-z0-9_.-]+\.(sh|py)' "$cfg" | sort -u)
check "sway config parses" 'command -v sway >/dev/null && sway -C >/dev/null 2>&1 || ! command -v sway >/dev/null'

# ---- sandbox
export HOME=$T/home XDG_RUNTIME_DIR=$T/run SANDBOX=$T
mkdir -p "$HOME/.config/sway" "$HOME/.local/bin" "$HOME/.local/share/palette" "$HOME/.cache" "$T/run" "$T/bin" "$T/apps"
cp "$src"/*.sh "$HOME/.config/sway/"
: >"$T/calls"
mk() {
    printf '%s\n' "$2" >"$T/bin/$1"
    chmod +x "$T/bin/$1"
}

mk swaymsg '#!/bin/bash
echo "swaymsg $*" >> "$SANDBOX/calls"
case "$*" in *get_tree*) for f in "$SANDBOX"/apps/*; do [ -e "$f" ] && echo "\"app_id\": \"$(basename "$f")\","; done;; esac
exit 0'
mk pgrep '#!/bin/bash
name=; for a in "$@"; do case $a in -*) ;; *) name=$a;; esac; done
[ "$name" = sway ] && { echo $$; exit 0; }
p=$SANDBOX/run/$name.pid; [ -f "$p" ] && kill -0 "$(cat "$p")" 2>/dev/null'
mk pkill '#!/bin/bash
name=; for a in "$@"; do case $a in -*) ;; *) name=$a;; esac; done
echo "pkill $*" >> "$SANDBOX/calls"
p=$SANDBOX/run/$name.pid; [ -f "$p" ] && kill "$(cat "$p")" 2>/dev/null; rm -f "$p"; exit 0'
mk gtklock '#!/bin/bash
echo "gtklock $*" >> "$SANDBOX/calls"
( echo $BASHPID > "$SANDBOX/run/gtklock.pid"; while [ ! -e "$SANDBOX/unlock" ]; do sleep 0.05; done; rm -f "$SANDBOX/run/gtklock.pid" ) >/dev/null 2>&1 &
exit 0'
mk swaylock 'echo "swaylock $*" >> "$SANDBOX/calls"; exit 1'
mk squeekboard '#!/bin/bash
echo "squeekboard" >> "$SANDBOX/calls"; exit 0'
mk python3 '#!/bin/bash
echo "python3 $*" >> "$SANDBOX/calls"; exit 0'
for app in alacritty:Alacritty firefox-esr:firefox-esr; do
    mk "${app%%:*}" "#!/bin/bash
echo \"${app%%:*}\" >> \"\$SANDBOX/calls\"; touch \"\$SANDBOX/apps/${app##*:}\"; exit 0"
done
printf '#!/bin/bash\necho zed >> "$SANDBOX/calls"; touch "$SANDBOX/apps/dev.zed.Zed"; exit 0\n' >"$HOME/.local/bin/zed"
chmod +x "$HOME/.local/bin/zed"
mk cliphist '#!/bin/bash
echo "cliphist $*" >> "$SANDBOX/calls"; exit 0'
mk plymouth '#!/bin/bash
echo "plymouth $*" >> "$SANDBOX/calls"; exit 0'
mk waybar '#!/bin/bash
echo "waybar" >> "$SANDBOX/calls"; touch "$XDG_RUNTIME_DIR/waybar-ready"; exit 0'
export PATH=$T/bin:$PATH
printf "[daemon]\nAutomaticLoginEnable=true\nAutomaticLogin=%s\n" "$USER" >"$T/gdm-auto.conf"
printf "[daemon]\n" >"$T/gdm-manual.conf"
export GDM_CONF=$T/gdm-auto.conf STARTUP_UPTIME=30

# ---- 1. session start
echo "session start (startup.sh)"
timeout 25 bash "$HOME/.config/sway/startup.sh" >/dev/null 2>&1
rc=$?
log=$HOME/.cache/startup.log
check "startup.sh finished by itself (rc=$rc)" '[ $rc -eq 0 ]'
check "boot splash told to quit (no 20 s hold-up)" 'grep -q "^plymouth quit" "$T/calls"'
check "the screen was locked first" 'grep -q "^gtklock -d" "$T/calls"'
check "lock came before any app" '[ "$(grep -n -m1 -E "^(gtklock|firefox-esr|zed|waybar|alacritty)" "$T/calls" | cut -d: -f2)" = "gtklock -d" ]'
for a in firefox-esr zed waybar alacritty; do
    check "launched $a" 'grep -qx "$a" "$T/calls"'
done
check "all four windows were noticed" 'grep -q "^desktop-ready" "$log" && grep -q "^zed-window" "$log" && grep -q "^firefox-window" "$log"'
check "frame kept while locked (startup-active)" '[ -e "$XDG_RUNTIME_DIR/startup-active" ]'
sleep 1.4
check "clipboard history wiped when the lock goes up" 'grep -q "^cliphist wipe" "$T/calls"'
check "wallpaper swapped once the lock covers the screen" 'grep -q "output \* bg .*wallpaper.png fill" "$T/calls"'

echo "a normal (non-autologin) login must NOT lock"
cp -r "$HOME/.cache" "$T/cache.keep"
: >"$T/calls"
rm -f "$T/apps"/* "$XDG_RUNTIME_DIR/startup-active" "$T/run/gtklock.pid"
GDM_CONF=$T/gdm-manual.conf timeout 25 bash "$HOME/.config/sway/startup.sh" >/dev/null 2>&1
check "no lock when autologin is off" '! grep -q "^gtklock" "$T/calls"'
check "...but the desktop still loads" 'grep -qx waybar "$T/calls" && grep -qx alacritty "$T/calls"'
check "...and the wallpaper is not held back" '[ ! -e "$XDG_RUNTIME_DIR/startup-active" ]'
: >"$T/calls"
rm -f "$T/apps"/* "$T/run/gtklock.pid" "$T/unlock"
STARTUP_UPTIME=9000 timeout 25 bash "$HOME/.config/sway/startup.sh" >/dev/null 2>&1
check "no lock on a late login (uptime 2.5 h)" '! grep -q "^gtklock" "$T/calls"'
# back to the autologin boot for the unlock checks below
: >"$T/calls"
rm -f "$T/apps"/* "$T/run/gtklock.pid" "$T/unlock"
timeout 25 bash "$HOME/.config/sway/startup.sh" >/dev/null 2>&1

# ---- 2. unlock
echo "unlock"
touch "$T/unlock"
for _ in $(seq 1 60); do
    [ -e "$XDG_RUNTIME_DIR/startup-active" ] || break
    sleep 0.1
done
sleep 0.5
check "marker cleared after unlock" '[ ! -e "$XDG_RUNTIME_DIR/startup-active" ]'
check "no work at the unlock instant (no bg swap, no render)" '! grep -q "quote-frame.py" "$T/calls"'
sleep 7
check "next quote frame prepared a few seconds later, at low priority" 'grep -q "quote-frame.py --render .*lock-frame.png --new" "$T/calls"'

# ---- 3. bg-state.sh (runs on every reload)
echo "bg-state.sh"
: >"$T/calls"
touch "$XDG_RUNTIME_DIR/startup-active"
bash "$HOME/.config/sway/bg-state.sh"
check "leaves the frame alone during startup" '! grep -q "output \* bg" "$T/calls"'
rm -f "$XDG_RUNTIME_DIR/startup-active"
: >"$T/calls"
bash "$HOME/.config/sway/bg-state.sh"
check "restores the wallpaper when idle and unlocked" 'grep -q "output \* bg .*wallpaper.png fill" "$T/calls"'
: >"$T/calls"
rm -f "$T/unlock"
bash "$HOME/.config/sway/lock.sh" >/dev/null 2>&1
bash "$HOME/.config/sway/bg-state.sh"
check "leaves it alone while the screen is locked" '! grep -q "output \* bg" "$T/calls"'
touch "$T/unlock"
sleep 1

# ---- 4. the real sway starting the real config (headless: no screen, isolated from this session)
echo "headless sway runs the real config"
if command -v sway >/dev/null 2>&1; then
    H=$T/h
    mkdir -p "$H/home/.config/sway" "$H/home/.local/bin" "$H/home/.local/share/palette" "$H/home/.cache" "$H/run" "$H/bin" "$H/apps"
    cp "$src"/* "$H/home/.config/sway/" 2>/dev/null
    # never include the system config.d (it imports variables into the real systemd --user manager)
    grep -v '^include /etc/sway/config.d' "$src/config" >"$H/home/.config/sway/config"
    printf 'set $bg #1e1e2e\nset $fg #cdd6f4\nset $dim #6c7086\nset $accent #cba6f7\nset $accent2 #89b4fa\nset $warn #f9e2af\nset $urgent #f38ba8\n' >"$H/home/.config/sway/colors.conf"
    : >"$H/home/.config/sway/style.conf"
    : >"$H/home/.config/sway/hyper.conf"
    sed -i 's|^output \* bg .*||' "$H/home/.config/sway/config"
    : >"$H/calls"
    hmk() {
        printf '%s\n' "$2" >"$H/bin/$1"
        chmod +x "$H/bin/$1"
    }
    for n in mako swayidle monitor-sensor lisgd squeekboard blueman-applet nm-applet wlr-which-key brightnessctl; do hmk $n 'exit 0'; done
    hmk swaymsg '#!/bin/bash
case "${SWAYSOCK:-}" in
    "$HSB"/run/*) exec /usr/bin/swaymsg "$@" ;;
    *) echo "swaymsg refused: not talking to the sandbox sway" >&2; exit 1 ;;
esac'
    hmk pgrep '#!/bin/bash
name=; for a in "$@"; do case $a in -*) ;; *) name=$a;; esac; done
[ "$name" = sway ] && { echo $PPID; exit 0; }
p=$HSB/run/$name.pid; [ -f "$p" ] && kill -0 "$(cat "$p")" 2>/dev/null'
    hmk pkill 'exit 0'
    hmk gtklock '#!/bin/bash
echo "gtklock $*" >> "$HSB/calls"
( echo $BASHPID > "$HSB/run/gtklock.pid"; while [ ! -e "$HSB/unlock" ]; do sleep 0.05; done; rm -f "$HSB/run/gtklock.pid" ) >/dev/null 2>&1 &'
    hmk swaylock 'exit 1'
    hmk python3 '#!/bin/bash
echo "python3 $*" >> "$HSB/calls"'
    for app in alacritty:Alacritty firefox-esr:firefox-esr; do
        hmk "${app%%:*}" "#!/bin/bash
echo \"${app%%:*}\" >> \"\$HSB/calls\"; exit 0"
    done
    printf '#!/bin/bash\necho zed >> "$HSB/calls"\n' >"$H/home/.local/bin/zed"
    chmod +x "$H/home/.local/bin/zed"
    hmk plymouth 'exit 0'
    hmk cliphist 'exit 0'
    hmk waybar '#!/bin/bash
echo waybar >> "$HSB/calls"; touch "$XDG_RUNTIME_DIR/waybar-ready"'
    (
        unset DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY SWAYSOCK I3SOCK DISPLAY
        export HOME=$H/home XDG_RUNTIME_DIR=$H/run HSB=$H STARTUP_POLLS=8 GDM_CONF=$T/gdm-auto.conf STARTUP_UPTIME=30
        export PATH=$H/bin:${PATH#$T/bin:} # the unit-test stand-ins must not leak in
        export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
        timeout 14 sway -c "$H/home/.config/sway/config" >"$H/sway.log" 2>&1 &
        for _ in $(seq 1 100); do
            grep -q '^desktop-ready' "$H/home/.cache/startup.log" 2>/dev/null && break
            sleep 0.1
        done
        sleep 0.3
        pkill_sway=$(pgrep -f "sway -c $H/home" 2>/dev/null | head -1)
        [ -n "$pkill_sway" ] && kill "$pkill_sway" 2>/dev/null
        wait 2>/dev/null
    )
    check "sway really ran startup.sh" '[ -s "$H/home/.cache/startup.log" ] && grep -q "^script-start" "$H/home/.cache/startup.log"'
    check "...and locked before anything else" 'grep -q "^gtklock" "$H/calls" && [ "$(head -1 "$H/calls" | cut -c1-7)" = gtklock ]'
    check "...and launched the bar and terminal" 'grep -qx waybar "$H/calls" && grep -qx alacritty "$H/calls"'
    check "...and launched zed and firefox" 'grep -qx zed "$H/calls" && grep -qx firefox-esr "$H/calls"'
    check "...and reached desktop-ready" 'grep -q "^desktop-ready" "$H/home/.cache/startup.log"'
else
    ok "sway not installed here: headless run skipped"
fi

echo
if [ $fail -eq 0 ]; then echo "startup test: PASS"; else echo "startup test: FAIL"; fi
exit $fail
