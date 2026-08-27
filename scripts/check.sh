#!/usr/bin/env bash
# scripts/check.sh -- static verification harness, run before every commit.
#
# Runs, in order: shellcheck on every .sh, bash -n / zsh -n syntax checks,
# stylua --check, the symlink pytest suite, the nvim config tests, and lua
# pretty.lua -l. A missing
# tool is its own loud failure, never a silent skip -- it must not be
# mistaken for "the check passed". Exits non-zero if any stage fails.
#
# Usage: ./scripts/check.sh   (runnable from anywhere inside the repo)
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

results=()
overall=0

pass() { results+=("PASS  $1"); }
fail() {
    results+=("FAIL  $1")
    overall=1
}
skip() { results+=("SKIP  $1 -- $2"); }
missing() {
    echo "ERROR: '$1' not found on PATH -- required for the '$2' stage" >&2
    results+=("FAIL  $2 (missing $1)")
    overall=1
}

sh_files=()
while IFS= read -r -d ''; do
    sh_files+=("$REPLY")
done < <(find . -path ./.git -prune -o -type f -name '*.sh' -print0)

# Extension-less shell scripts the *.sh glob above can't see: dotfiles meant
# to be sourced, not executed (.bashrc, .profile), plus the pre-commit hook
# itself. Listed explicitly rather than sniffed by shebang, since this repo
# also has extension-less non-shell files (.githooks/commit-msg is Perl,
# bashrc/.ssh/config is an ssh_config) that must stay out of this list.
for f in bashrc/.bashrc bashrc/.profile .githooks/pre-commit; do
    [ -f "$f" ] && sh_files+=("$f")
done

# .zshrc (M08) uses zsh-only syntax (setopt, the (N) glob qualifier) that
# neither shellcheck nor bash -n understand, so it gets its own list checked
# only by zsh -n below -- not folded into sh_files.
zsh_only_files=()
[ -f bashrc/.zshrc ] && zsh_only_files+=(bashrc/.zshrc)

lua_files=()
while IFS= read -r -d ''; do
    lua_files+=("$REPLY")
done < <(find . -path ./.git -prune -o -type f -name '*.lua' -print0)

echo "==> shellcheck"
if ! command -v shellcheck >/dev/null 2>&1; then
    missing shellcheck shellcheck
elif shellcheck "${sh_files[@]}"; then
    pass shellcheck
else
    fail shellcheck
fi

echo "==> bash -n"
if ! command -v bash >/dev/null 2>&1; then
    missing bash "bash -n"
else
    bash_ok=0
    for f in "${sh_files[@]}"; do
        bash -n "$f" || bash_ok=1
    done
    if [ "$bash_ok" -eq 0 ]; then pass "bash -n"; else fail "bash -n"; fi
fi

echo "==> zsh -n"
if ! command -v zsh >/dev/null 2>&1; then
    missing zsh "zsh -n"
else
    zsh_ok=0
    for f in "${sh_files[@]}" "${zsh_only_files[@]}"; do
        zsh -n "$f" || zsh_ok=1
    done
    if [ "$zsh_ok" -eq 0 ]; then pass "zsh -n"; else fail "zsh -n"; fi
fi

echo "==> stylua --check"
if ! command -v stylua >/dev/null 2>&1; then
    missing stylua "stylua --check"
elif [ "${#lua_files[@]}" -eq 0 ]; then
    skip "stylua --check" "no .lua files found"
elif stylua --check "${lua_files[@]}"; then
    pass "stylua --check"
else
    fail "stylua --check"
fi

echo "==> pytest (symlink tests)"
# The `pytest` executable is tried before `python3 -m pytest`. They are not
# interchangeable: apt's python3-pytest installs the module under /usr/bin/
# python3, while PATH may well resolve python3 to a pyenv/uv/venv interpreter
# that has no pytest at all -- which reports "missing pytest" on a machine that
# has it, and quietly turns a real test stage into a permanent non-result. The
# executable carries its own shebang, so it always points at an interpreter
# where pytest is importable.
pytest_cmd=()
if command -v pytest >/dev/null 2>&1; then
    pytest_cmd=(pytest)
elif command -v python3 >/dev/null 2>&1 && python3 -m pytest --version >/dev/null 2>&1; then
    pytest_cmd=(python3 -m pytest)
fi

if [ ! -d tests ] || ! find tests -name 'test_symlink*.py' -print -quit | grep -q .; then
    skip "pytest (symlink tests)" "tests/test_symlink.py not present yet -- lands in M04"
elif [ "${#pytest_cmd[@]}" -eq 0 ]; then
    missing pytest "pytest (symlink tests)"
elif "${pytest_cmd[@]}" tests/; then
    pass "pytest (symlink tests)"
else
    fail "pytest (symlink tests)"
fi

echo "==> nvim config tests"
if ! command -v nvim >/dev/null 2>&1; then
    missing nvim "nvim config tests"
elif nvim/tests/run.sh; then
    pass "nvim config tests"
else
    fail "nvim config tests"
fi

echo "==> lua pretty.lua -l"
if ! command -v lua >/dev/null 2>&1; then
    missing lua "lua pretty.lua -l"
elif lua pretty.lua -l; then
    pass "lua pretty.lua -l"
else
    fail "lua pretty.lua -l"
fi

echo
echo "==> Summary"
for r in "${results[@]}"; do
    echo "  $r"
done

exit "$overall"
