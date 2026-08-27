#!/usr/bin/env bash
# scripts/usage-report.sh -- what of this repo's ~130 aliases and functions is
# actually being used.
#
# Cross-references every alias and wfn-registered function declared under
# bashrc/ against the log written by
# bashrc/.shell_modules/core/usage_tracking.sh. Answers the only question that
# matters for a cleanup: which of these can be deleted without anyone noticing.
#
# Usage:
#   ./scripts/usage-report.sh              # summary + unused list
#   ./scripts/usage-report.sh --used       # only what is used, by frequency
#   ./scripts/usage-report.sh --unused     # only what is not
#   ./scripts/usage-report.sh --all        # both
#   ./scripts/usage-report.sh --json       # machine-readable
#   ./scripts/usage-report.sh --dead-files # static: files nothing references
#
# The log needs weeks to mean anything. A shortcut unused for three days is not
# evidence; one unused for a month of normal work is.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

log="${DOTFILES_USAGE_LOG:-$HOME/.local/state/dotfiles/usage.tsv}"
mode="default"

while [ "$#" -gt 0 ]; do
    case "$1" in
    --used) mode="used" ;;
    --unused) mode="unused" ;;
    --all) mode="all" ;;
    --json) mode="json" ;;
    --dead-files) mode="dead-files" ;;
    -h | --help)
        sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        echo "unknown option: $1" >&2
        exit 2
        ;;
    esac
    shift
done

# ---------------------------------------------------------------- declarations
# name<TAB>kind<TAB>source:line, for every shortcut this repo defines.
declarations() {
    # Static alias definitions. The wfn-generated `alias x='__fn_wrapper x'`
    # ones are built at runtime and never appear here, so functions below do
    # not get double-counted.
    grep -rnE "^[[:space:]]*alias [A-Za-z0-9_.:+-]+=" bashrc/ 2>/dev/null |
        sed -E 's|^bashrc/(\.shell_modules/)?||' |
        sed -E 's/^([^:]+):([0-9]+):[[:space:]]*alias ([A-Za-z0-9_.:+-]+)=.*/\3\talias\t\1:\2/'

    grep -rnE "^wfn [A-Za-z0-9_.-]+" bashrc/ 2>/dev/null |
        sed -E 's|^bashrc/(\.shell_modules/)?||' |
        sed -E 's/^([^:]+):([0-9]+):wfn ([A-Za-z0-9_.-]+).*/\3\tfunction\t\1:\2/'
}

# ------------------------------------------------------------------- dead files
if [ "$mode" = "dead-files" ]; then
    echo "Files nothing else in the repo references:"
    echo
    found=0
    while IFS= read -r file; do
        base="$(basename "$file")"
        # Entrypoints and auto-discovered files are referenced by convention,
        # not by name, so a grep for them proves nothing.
        case "$file" in
        ./bootstrap.sh | ./symlink.py | ./configure_git.sh) continue ;;
        ./scripts/check.sh | ./scripts/doctor.sh) continue ;;
        ./scripts/doctor.d/* | ./bashrc/* | ./nvim/* | ./tests/*) continue ;;
        ./.githooks/*) continue ;;
        esac
        hits="$(grep -rlF "$base" . \
            --exclude-dir=.git --exclude-dir=node_modules \
            --exclude="$base" 2>/dev/null | grep -cv '^$' || true)"
        if [ "$hits" -eq 0 ]; then
            echo "  $file"
            found=$((found + 1))
        fi
    done < <(find . -path ./.git -prune -o -type f \( -name '*.sh' -o -name '*.py' -o -name '*.lua' \) -print | sort)
    [ "$found" -eq 0 ] && echo "  (none)"
    echo
    echo "Referenced by nothing is not the same as unused -- check before deleting."
    exit 0
fi

# ------------------------------------------------------------------- usage data
# One row per NAME. A name can legitimately be declared more than once -- the
# if/else fallbacks in tools/search.sh and tools/eza.sh define ff/ll/la twice,
# once per branch -- and counting those as two shortcuts would inflate every
# total. Extra locations are noted rather than listed.
declared="$(declarations | sort -u | awk -F'\t' '
    { n[$1]++; if (!(($1) in first)) { first[$1] = $2 "\t" $3 } }
    END { for (k in first) {
        extra = (n[k] > 1) ? " (+" n[k]-1 " more)" : ""
        print k "\t" first[k] extra
    } }
' | sort)"
total="$(printf '%s\n' "$declared" | grep -c . || true)"

if [ ! -f "$log" ]; then
    if [ "$mode" = "json" ]; then
        printf '{"log":"%s","exists":false,"declared":%s}\n' "$log" "$total"
    else
        echo "No usage log at $log"
        echo
        echo "$total shortcuts are declared, but nothing has been recorded yet."
        echo "Tracking starts with the next new shell; check back in a month."
    fi
    exit 0
fi

# name -> count, for names this repo actually declares.
counts="$(cut -f3 "$log" 2>/dev/null | sort | uniq -c | awk '{print $2"\t"$1}' || true)"

first_ts="$(head -1 "$log" | cut -f1)"
now="$(date +%s)"
days=$(((now - first_ts) / 86400))
entries="$(grep -c . "$log" || true)"

lookup_count() {
    printf '%s\n' "$counts" | awk -F'\t' -v n="$1" '$1 == n {print $2; found=1} END {if (!found) print 0}'
}

used_rows=""
unused_rows=""
used_n=0
unused_n=0
while IFS=$'\t' read -r name kind where; do
    [ -n "$name" ] || continue
    c="$(lookup_count "$name")"
    if [ "$c" -gt 0 ]; then
        used_rows="${used_rows}${c}\t${name}\t${kind}\t${where}\n"
        used_n=$((used_n + 1))
    else
        unused_rows="${unused_rows}${name}\t${kind}\t${where}\n"
        unused_n=$((unused_n + 1))
    fi
done <<<"$declared"

if [ "$mode" = "json" ]; then
    printf '{"log":"%s","exists":true,"days":%s,"entries":%s,' "$log" "$days" "$entries"
    printf '"declared":%s,"used":%s,"unused":%s,"unused_names":[' "$total" "$used_n" "$unused_n"
    printf '%b' "$unused_rows" | awk -F'\t' 'NF{printf "%s\"%s\"", (NR>1?",":""), $1}'
    printf ']}\n'
    exit 0
fi

echo "Usage report"
echo "  log      $log"
echo "  window   ${days} day(s), $entries commands recorded"
echo "  declared $total shortcuts -- $used_n used, $unused_n never used"
if [ "$days" -lt 14 ]; then
    echo
    echo "  NOTE: only ${days} day(s) of data. Too early to delete anything on this."
fi

if [ "$mode" = "used" ] || [ "$mode" = "all" ]; then
    echo
    echo "USED ($used_n), most frequent first:"
    printf '%b' "$used_rows" | sort -rn | awk -F'\t' 'NF{printf "  %6s  %-18s %-9s %s\n", $1, $2, $3, $4}'
fi

if [ "$mode" = "default" ] || [ "$mode" = "unused" ] || [ "$mode" = "all" ]; then
    echo
    echo "NEVER USED ($unused_n) -- deletion candidates:"
    printf '%b' "$unused_rows" | sort | awk -F'\t' 'NF{printf "  %-18s %-9s %s\n", $1, $2, $3}'
fi
