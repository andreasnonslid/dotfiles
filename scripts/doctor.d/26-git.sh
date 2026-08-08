#!/usr/bin/env bash
# scripts/doctor.d/26-git.sh -- git identity include files (M29).
#
# Sourced by scripts/doctor.sh, which already defines doctor_pass/
# doctor_warn/doctor_fail, sets $root and $current_section, and has
# lib/os.sh sourced. This file must not be run standalone.
#
# bashrc/.gitconfig carries no [user] section -- it's tracked in git, so a
# hardcoded name/email would leak into commit history. Both the personal
# (default) and work identities come from machine-local include files
# instead. Missing files aren't a git error (include/includeIf silently
# skip a missing path), so the first symptom would otherwise be a
# confusing "Author identity unknown" on the very first commit. This only
# checks the files this scheme depends on actually exist -- confirming the
# includeIf actually resolves to the right identity inside ~/work/ vs
# elsewhere is D05's job, once M32 also lands.

section="git"

personal="$HOME/.local/secrets/git/personal.gitconfig"
work="$HOME/.local/secrets/git/work.gitconfig"

if [ -f "$personal" ]; then
    doctor_pass "$section" "Personal git identity found: $personal"
else
    doctor_warn "$section" "Personal git identity missing: $personal" \
        "Commits outside ~/work/ will fail with 'Author identity unknown' -- see README.md's Git identity section."
fi

if [ -f "$work" ]; then
    doctor_pass "$section" "Work git identity found: $work"
else
    doctor_warn "$section" "Work git identity missing: $work" \
        "Commits under ~/work/ fall back to the personal identity (or fail too, if that's also missing) -- see README.md's Git identity section."
fi
