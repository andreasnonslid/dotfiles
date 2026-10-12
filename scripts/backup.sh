#!/usr/bin/env bash
# Encrypted, deduplicated backups of your home with restic, to another machine over SSH.
# Nothing readable ever leaves the laptop: restic encrypts first.
#
#   scripts/backup.sh setup HOST USER PATH   one-time: write the config, make the repo, store a password
#   scripts/backup.sh                         back up now (also what `dots backup` runs)
#   scripts/backup.sh status                  snapshots and sizes
#   scripts/backup.sh restore SNAP DIR [PATH] restore (SNAP can be "latest") into DIR
#
# The restic password lives in ~/.config/dots/restic-password. KEEP A COPY OFF THIS MACHINE (your
# password manager): without it the backups cannot be read, and if the laptop dies it dies with it.
set -euo pipefail
cfg=${XDG_CONFIG_HOME:-$HOME/.config}/dots
state=${XDG_STATE_HOME:-$HOME/.local/state}/dots
conf=$cfg/backup.conf
pw=$cfg/restic-password
mkdir -p "$cfg" "$state"

need() { command -v "$1" >/dev/null 2>&1 || { echo "backup: $1 is not installed (sudo apt install $1)"; exit 1; }; }
need restic

if [ "${1:-}" = setup ]; then
    host=${2:?host} user=${3:?user} path=${4:?path on the host}
    [ -f "$pw" ] || { umask 077; head -c 32 /dev/urandom | base64 > "$pw"; }
    umask 077
    printf 'RESTIC_REPOSITORY=sftp:%s@%s:%s\nRESTIC_PASSWORD_FILE=%s\n' "$user" "$host" "$path" "$pw" > "$conf"
    set -a; . "$conf"; set +a
    restic snapshots >/dev/null 2>&1 || restic init
    echo
    echo "repository ready: $RESTIC_REPOSITORY"
    echo "NOW copy this password into your password manager (it is the only key to the backups):"
    echo
    cat "$pw"
    echo
    exit 0
fi

[ -f "$conf" ] || { echo "backup: not set up. Run: scripts/backup.sh setup HOST USER PATH"; exit 1; }
set -a; . "$conf"; set +a

excludes=$(mktemp); trap 'rm -f "$excludes"' EXIT
cat > "$excludes" <<'X'
# rebuildable or huge: not worth backing up
.cache
.local/share/Steam
.local/share/cursor-agent
.local/share/claude
.local/share/zed
.local/share/nvim
.rustup
.cargo
.pyenv
flutter
snap
Downloads
**/target
**/node_modules
**/build
**/.venv
**/__pycache__
.mozilla/firefox/*/cache2
.config/google-chrome
.config/BraveSoftware/*/Cache
.config/Cursor/Cache*
.config/Cursor/CachedData
X

case "${1:-run}" in
    run|"")
        restic backup "$HOME" --exclude-file "$excludes" --one-file-system --tag dots --host "$(hostname)"
        date +%s > "$state/last-backup"
        # thin out old snapshots (keeps a week of dailies, a month of weeklies, half a year of monthlies)
        restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune --tag dots
        ;;
    status) restic snapshots --compact; echo; restic stats latest 2>/dev/null | tail -3 ;;
    restore) restic restore "${2:?snapshot or latest}" --target "${3:?target dir}" ${4:+--include "$4"} ;;
    *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
