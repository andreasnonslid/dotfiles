#!/usr/bin/env bash
# scripts/doctor.d/50-usage.sh -- is shortcut usage tracking actually running,
# and has it collected enough to act on.
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/doctor_warn/
# doctor_fail, sets $root and $current_section, and has lib/os.sh sourced.
# This file must not be run standalone.
#
# Reports the summary only. `scripts/usage-report.sh` prints the lists.

# shellcheck disable=SC2154  # $root: set by scripts/doctor.sh before sourcing.

usage_log="${DOTFILES_USAGE_LOG:-$HOME/.local/state/dotfiles/usage.tsv}"

if [ "${DOTFILES_USAGE_TRACK:-1}" != "1" ]; then
    doctor_warn "tracking" "Shortcut usage tracking is disabled (DOTFILES_USAGE_TRACK=0)" \
        "Unset it and open a new shell if you want usage data for the next cleanup."
elif [ ! -f "$usage_log" ]; then
    doctor_warn "tracking" "No usage log yet at $usage_log" \
        "It is written by the first new shell after this repo is linked. Open one, run a command, re-check."
else
    usage_entries="$(grep -c . "$usage_log" 2>/dev/null || echo 0)"
    usage_first="$(head -1 "$usage_log" | cut -f1)"
    case "$usage_first" in
    '' | *[!0-9]*) usage_first="$(date +%s)" ;;
    esac
    usage_days=$((($(date +%s) - usage_first) / 86400))

    if [ "$usage_days" -lt 14 ]; then
        doctor_pass "tracking" \
            "Usage tracking live: $usage_entries commands over ${usage_days}d (needs ~30d to act on)"
    else
        doctor_pass "tracking" "Usage tracking live: $usage_entries commands over ${usage_days}d"
    fi

    # Only worth surfacing once there is enough data to mean something.
    if [ "$usage_days" -ge 30 ] && [ -x "$root/scripts/usage-report.sh" ]; then
        usage_json="$("$root/scripts/usage-report.sh" --json 2>/dev/null || echo '{}')"
        usage_unused="$(printf '%s' "$usage_json" | sed -n 's/.*"unused":\([0-9]*\).*/\1/p')"
        usage_declared="$(printf '%s' "$usage_json" | sed -n 's/.*"declared":\([0-9]*\).*/\1/p')"
        if [ -n "$usage_unused" ] && [ "$usage_unused" -gt 0 ]; then
            doctor_warn "unused" \
                "$usage_unused of $usage_declared shortcuts unused in ${usage_days}d" \
                "Review with ./scripts/usage-report.sh --unused, then delete what you do not miss."
        else
            doctor_pass "unused" "Every declared shortcut has been used at least once"
        fi
    fi
fi
