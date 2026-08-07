#!/usr/bin/env bash
# scripts/doctor.d/10-symlinks.sh -- symlink integrity check.
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# The expected link set is never hand-copied here -- that would drift from
# symlink.py (M03) the moment either side changes. Instead this runs
# symlink.py for real against a scratch $HOME and walks the tree it
# produces, exactly like tests/test_symlink.py does. Whatever symlink.py
# would create on this OS *is* the manifest.
#
# shellcheck disable=SC2154  # $root: set by scripts/doctor.sh before sourcing.

section="symlinks"

# realpath(1) isn't available everywhere and readlink -f is GNU-only (no -f
# on macOS's BSD readlink in general), so canonicalise via python3 -- already
# a hard dependency, since it's what runs symlink.py itself.
resolve() {
    python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

if ! command -v python3 >/dev/null 2>&1; then
    doctor_fail "$section" "python3 not found" "symlink.py (and this check) require python3."
else
    scratch="$(mktemp -d)"
    repo_real="$(resolve "$root")"

    if ! HOME="$scratch" python3 "$root/symlink.py" -y >/dev/null 2>&1; then
        doctor_fail "$section" "symlink.py errored on a dry run against a scratch \$HOME" \
            "Run 'python3 symlink.py -y' by hand to see the error."
    else
        missing="" not_symlink="" dangling="" wrong_in_repo="" outside_repo=""
        ok_count=0
        link_count=0

        while IFS= read -r -d '' link; do
            link_count=$((link_count + 1))
            rel="${link#"$scratch"/}"
            expected_target="$(resolve "$link")"
            real_link="$HOME/$rel"

            if [ ! -e "$real_link" ] && [ ! -L "$real_link" ]; then
                missing="${missing}${missing:+, }$rel"
            elif [ ! -L "$real_link" ]; then
                not_symlink="${not_symlink}${not_symlink:+, }$rel"
            elif [ ! -e "$real_link" ]; then
                dangling="${dangling}${dangling:+, }$rel"
            else
                real_target="$(resolve "$real_link")"
                case "$real_target" in
                "$repo_real" | "$repo_real"/*)
                    if [ "$real_target" = "$expected_target" ]; then
                        ok_count=$((ok_count + 1))
                    else
                        wrong_in_repo="${wrong_in_repo}${wrong_in_repo:+, }$rel"
                    fi
                    ;;
                *)
                    outside_repo="${outside_repo}${outside_repo:+, }$rel -> $real_target"
                    ;;
                esac
            fi
        done < <(find "$scratch" -type l -print0)

        if [ "$link_count" -eq 0 ]; then
            doctor_warn "$section" "symlink.py's dry run produced no links to check" \
                "Unexpected -- check bashrc/, nvim/ and caveman/ exist in this checkout."
        else
            [ -n "$missing" ] && doctor_fail "$section" "Expected link(s) missing: $missing" \
                "Bootstrap didn't run, or ran partially -- run ./bootstrap.sh."
            [ -n "$not_symlink" ] && doctor_fail "$section" "Expected link(s) exist but aren't symlinks: $not_symlink" \
                "Likely a real file left in place instead of being linked -- check the .bak-* report below."
            [ -n "$dangling" ] && doctor_fail "$section" "Dangling symlink(s) (target missing): $dangling" \
                "The link exists but its target is gone -- re-run ./bootstrap.sh."
            [ -n "$wrong_in_repo" ] && doctor_fail "$section" "Link(s) resolve into the repo but not to the expected target: $wrong_in_repo" \
                "Stale from a previous layout -- re-run ./bootstrap.sh."
            [ -n "$outside_repo" ] && doctor_fail "$section" "Link(s) resolve outside this repo checkout: $outside_repo" \
                "Stale link from another dotfiles checkout -- remove it and re-run ./bootstrap.sh."

            if [ -z "$missing$not_symlink$dangling$wrong_in_repo$outside_repo" ]; then
                doctor_pass "$section" "All $ok_count expected links present and resolve into the repo"
            fi
        fi
    fi

    rm -rf "$scratch"
fi

# .bak-* files: symlink.py backs up a pre-existing real file instead of
# clobbering it, silently. Surface any left behind so they don't go unnoticed
# forever. Top-level only -- that's the only place symlink.py ever writes one.
bak_found=""
for dir in "$HOME" "$HOME/.config"; do
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' f; do
        bak_found="${bak_found}${bak_found:+, }${f}"
    done < <(find "$dir" -maxdepth 1 -name '*.bak-*' -print0 2>/dev/null)
done
if [ -n "$bak_found" ]; then
    doctor_warn "$section" "Backup file(s) from a symlink clobber found: $bak_found" \
        "symlink.py moved a pre-existing real file aside instead of overwriting it -- review, then delete once confirmed unneeded."
else
    doctor_pass "$section" "No .bak-* files under \$HOME or \$HOME/.config"
fi
