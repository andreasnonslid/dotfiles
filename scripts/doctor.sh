#!/usr/bin/env bash
# scripts/doctor.sh -- runtime diagnostics for the machine this runs on.
#
# Unlike scripts/check.sh (repo consistency, runs in the Linux container),
# doctor.sh answers "does this machine actually work?". It is meant to run
# on the real target machine, both pre-flight (before bootstrap, to see
# what's missing) and post-flight (after, as the acceptance gate). It must
# degrade gracefully -- a bare, untouched machine failing every check is
# the expected pre-flight baseline, not a crash.
#
# Checks are auto-discovered from scripts/doctor.d/*.sh, sourced in sorted
# filename order. Each module calls doctor_pass/doctor_warn/doctor_fail
# (defined below) for whatever it checks. The section a check is grouped
# under comes from its module's filename: everything after the first '-'
# (e.g. "00-core.sh" -> section "core").
#
# Usage: ./scripts/doctor.sh [--verbose] [--json] [--only <section>]
set -uo pipefail # no -e: a check "failing" must not abort the whole run

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1
# shellcheck source=lib/os.sh
. "$root/lib/os.sh"

verbose=0
json=0
only=""

usage() {
    cat <<'EOF'
Usage: doctor.sh [--verbose] [--json] [--only <section>] [-h|--help]

  --verbose         show hints for every check, not just WARN/FAIL
  --json            machine-readable output (for agents to parse)
  --only <section>  run only the named section's checks
  -h, --help        show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
    --verbose)
        verbose=1
        shift
        ;;
    --json)
        json=1
        shift
        ;;
    --only)
        only="${2:-}"
        shift 2
        ;;
    --only=*)
        only="${1#--only=}"
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "doctor.sh: unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
done

# Parallel arrays -- one entry per check, appended in the order checks run.
check_sections=()
check_names=()
check_statuses=()
check_messages=()
check_hints=()

# doctor_report is what doctor_pass/warn/fail funnel through; doctor.d
# modules should only ever call the three below, not this directly.
#
# All four are only ever called from scripts/doctor.d/*.sh modules, sourced
# dynamically below -- shellcheck can't see those call sites and would
# otherwise flag every one of these as unreachable (SC2317).
# shellcheck disable=SC2317
doctor_report() {
    check_sections+=("$current_section")
    check_names+=("$1")
    check_statuses+=("$2")
    check_messages+=("$3")
    check_hints+=("${4:-}")
}

# shellcheck disable=SC2317
doctor_pass() { doctor_report "$1" PASS "$2" "${3:-}"; }
# shellcheck disable=SC2317
doctor_warn() { doctor_report "$1" WARN "$2" "${3:-}"; }
# shellcheck disable=SC2317
doctor_fail() { doctor_report "$1" FAIL "$2" "${3:-}"; }

shopt -s nullglob
modules=("$root"/scripts/doctor.d/*.sh)
shopt -u nullglob

modules_run=0
for module in "${modules[@]}"; do
    base="$(basename "$module" .sh)"
    current_section="${base#*-}"
    if [ -n "$only" ] && [ "$only" != "$current_section" ]; then
        continue
    fi
    modules_run=$((modules_run + 1))
    # shellcheck source=/dev/null
    . "$module"
done

total=${#check_names[@]}
pass_count=0
warn_count=0
fail_count=0
for status in "${check_statuses[@]}"; do
    case "$status" in
    PASS) pass_count=$((pass_count + 1)) ;;
    WARN) warn_count=$((warn_count + 1)) ;;
    FAIL) fail_count=$((fail_count + 1)) ;;
    esac
done

exit_code=0
[ "$fail_count" -gt 0 ] && exit_code=1

if [ "$json" -eq 1 ]; then
    json_escape() {
        local s=$1
        s=${s//\\/\\\\}
        s=${s//\"/\\\"}
        s=${s//$'\n'/\\n}
        printf '%s' "$s"
    }

    printf '{\n  "checks": [\n'
    for i in "${!check_names[@]}"; do
        printf '    {"section": "%s", "name": "%s", "status": "%s", "message": "%s", "hint": "%s"}' \
            "$(json_escape "${check_sections[$i]}")" \
            "$(json_escape "${check_names[$i]}")" \
            "$(json_escape "${check_statuses[$i]}")" \
            "$(json_escape "${check_messages[$i]}")" \
            "$(json_escape "${check_hints[$i]}")"
        [ "$i" -lt $((total - 1)) ] && printf ','
        printf '\n'
    done
    printf '  ],\n'
    printf '  "summary": {"pass": %d, "warn": %d, "fail": %d, "total": %d},\n' \
        "$pass_count" "$warn_count" "$fail_count" "$total"
    printf '  "exit_code": %d\n' "$exit_code"
    printf '}\n'
    exit "$exit_code"
fi

color=0
[ -t 1 ] && color=1

c_reset="" c_pass="" c_warn="" c_fail="" c_bold=""
if [ "$color" -eq 1 ]; then
    c_reset=$'\033[0m'
    c_pass=$'\033[32m'
    c_warn=$'\033[33m'
    c_fail=$'\033[31m'
    c_bold=$'\033[1m'
fi

if [ "$total" -eq 0 ]; then
    echo "No checks registered under scripts/doctor.d/ (or --only matched nothing)."
else
    seen_sections=()
    for i in "${!check_names[@]}"; do
        section="${check_sections[$i]}"
        already_seen=0
        for s in "${seen_sections[@]}"; do
            [ "$s" = "$section" ] && already_seen=1 && break
        done
        if [ "$already_seen" -eq 0 ]; then
            seen_sections+=("$section")
            [ "$i" -gt 0 ] && echo
            echo "${c_bold}==> ${section}${c_reset}"
        fi

        status="${check_statuses[$i]}"
        case "$status" in
        PASS) sc="$c_pass" ;;
        WARN) sc="$c_warn" ;;
        FAIL) sc="$c_fail" ;;
        *) sc="" ;;
        esac

        printf '  %s%-4s%s  %-16s  %s\n' "$sc" "$status" "$c_reset" "${check_names[$i]}" "${check_messages[$i]}"

        hint="${check_hints[$i]}"
        if [ -n "$hint" ] && { [ "$verbose" -eq 1 ] || [ "$status" != "PASS" ]; }; then
            printf '        hint: %s\n' "$hint"
        fi
    done
    echo
fi

echo "${c_bold}==> Summary${c_reset}"
echo "  ${c_pass}${pass_count} passed${c_reset}, ${c_warn}${warn_count} warned${c_reset}, ${c_fail}${fail_count} failed${c_reset} (${total} total)"
[ "$modules_run" -eq 0 ] && echo "  (no doctor.d modules matched)"

exit "$exit_code"
