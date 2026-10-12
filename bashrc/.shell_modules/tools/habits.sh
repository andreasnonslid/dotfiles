# Local habit log: one TSV line per command (epoch, exit status, directory, command), so what you
# actually do can be measured: scripts/habits.py reads it. Stays on this machine (mode 600).
# Skipped: commands starting with a space, and anything that looks like it carries a secret.
[ -n "${BASH_VERSION:-}" ] || return 0
case $- in *i*) ;; *) return 0 ;; esac

__HABIT_LOG="${XDG_DATA_HOME:-$HOME/.local/share}/habits/commands.tsv"
__HABIT_RAN=
__HABIT_X=      # must be set (even empty): bash skips the arithmetic below for an unset variable

# PS0 is expanded once per executed command line, whatever HISTCONTROL (ignoredups/erasedups) does to
# the history list; the arithmetic side effect flags "a command ran" without printing anything.
__HABIT_PS0='${__HABIT_X:0:$((__HABIT_RAN=1,0))}'

__habit_log() {
    local rc=$? line cmd
    case $PS0 in *__HABIT_RAN*) ;; *) PS0="${PS0}${__HABIT_PS0}" ;; esac   # (re)install after other inits
    [ -n "$__HABIT_RAN" ] || return $rc            # empty Enter, or nothing ran
    __HABIT_RAN=
    line=$(HISTTIMEFORMAT= builtin history 1) || return $rc
    cmd=${line#"${line%%[![:space:]]*}"}           # drop leading spaces
    cmd=${cmd#"${cmd%%[[:space:]]*}"}              # drop the history number
    cmd=${cmd#"${cmd%%[![:space:]]*}"}             # ...and the spaces after it
    case $cmd in ""|" "*) return $rc ;; esac
    case ${cmd,,} in *token*|*passw*|*secret*|*api_key*|*apikey*|*bearer*|*authorization*|*ghp_*|*sk-*|*private*key*) return $rc ;; esac
    [ -d "${__HABIT_LOG%/*}" ] || { mkdir -p "${__HABIT_LOG%/*}" && chmod 700 "${__HABIT_LOG%/*}"; }
    printf '%(%s)T\t%d\t%s\t%s\n' -1 "$rc" "$PWD" "$cmd" >> "$__HABIT_LOG"
    return $rc
}

# first in PROMPT_COMMAND, and it hands the original exit status on (e.g. to the starship prompt)
case ";${PROMPT_COMMAND:-};" in
    *";__habit_log;"*) ;;
    *) PROMPT_COMMAND="__habit_log${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
