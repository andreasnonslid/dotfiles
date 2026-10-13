#!/usr/bin/env bash
# Boot straight into the Sway session, where the lock screen is the login ("unlock, don't log in").
# Only the FIRST login after power-on is automatic; after a logout GDM shows its normal greeter, so
# you can still pick GNOME there.  Idempotent.
#   sudo linux/install-autologin.sh        turn it on
#   sudo linux/install-autologin.sh --off  turn it off again (back to the GDM login screen)
set -euo pipefail
[ "$(id -u)" = 0 ] || {
    echo "run with sudo"
    exit 1
}
user=${SUDO_USER:?run with sudo}
conf=/etc/gdm3/daemon.conf
acct=/var/lib/AccountsService/users/$user
mode=on
[ "${1:-}" = "--off" ] && mode=off

cp -a "$conf" "$conf.pre-autologin" 2>/dev/null || true
python3 - "$conf" "$user" "$mode" <<'PY'
import re, sys
conf, user, mode = sys.argv[1:4]
text = open(conf).read()
want = {"AutomaticLoginEnable": "true" if mode == "on" else "false", "AutomaticLogin": user}
m = re.search(r"^\[daemon\]\s*$", text, re.M)
assert m, "no [daemon] section in " + conf
end = re.search(r"^\[", text[m.end():], re.M)
stop = m.end() + end.start() if end else len(text)
body = text[m.end():stop]
for k, v in want.items():
    if re.search(rf"^\s*#?\s*{k}\s*=", body, re.M):
        body = re.sub(rf"^\s*#?\s*{k}\s*=.*$", f"{k}={v}", body, count=1, flags=re.M)
    else:
        body = body.rstrip("\n") + f"\n{k}={v}\n"
open(conf, "w").write(text[:m.end()] + body + text[stop:])
PY

# GDM starts the user's saved session; make sure that is Sway.
if [ "$mode" = on ]; then
    if [ -f "$acct" ]; then
        grep -q '^Session=' "$acct" && sed -i 's/^Session=.*/Session=sway/' "$acct" || sed -i '/^\[User\]/a Session=sway' "$acct"
    else
        printf '[User]\nSession=sway\n' >"$acct"
    fi
fi
echo "autologin $mode for $user"
grep -E '^(AutomaticLogin|AutomaticLoginEnable)' "$conf"
grep -E '^Session=' "$acct" 2>/dev/null || true
echo "backup of the old config: $conf.pre-autologin"
