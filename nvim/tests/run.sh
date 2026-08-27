#!/usr/bin/env bash
# nvim/tests/run.sh -- behaviour tests for this Neovim config.
#
# check.sh answers "is the repo internally consistent" (formatting, syntax).
# These answer "does the config still do what its README says", which is the
# part that breaks silently: a keymap quietly shadowed, a plugin renamed
# upstream, an index that stops regenerating.
#
# Each spec runs in its own nvim against a COPY of nvim/, never the working
# tree: lazy writes lazy-lock.json next to the config it loads, and a test run
# must not dirty a tracked file.
#
# Plugins are installed once into a persistent cache, so only the first run
# pays for the clones.
#
# Usage: nvim/tests/run.sh [spec-name ...]   (default: all)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nvim_config_src="$(dirname "$here")"

if ! command -v nvim >/dev/null 2>&1; then
    echo "ERROR: 'nvim' not found on PATH -- required to run the nvim config tests" >&2
    exit 1
fi

# 0.11 lacks APIs the config's plugins use (vim.list.*), so a run there reports
# upstream's incompatibility rather than anything about this repo.
if ! nvim --headless -c 'lua if vim.fn.has("nvim-0.11") ~= 1 then vim.cmd("cq") end' -c 'qa!' 2>/dev/null; then
    echo "ERROR: these tests need Neovim 0.11+; found $(nvim --version | head -1)" >&2
    exit 1
fi

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-nvim-tests"
run_root="$(mktemp -d)"
trap 'rm -rf "$run_root"' EXIT

# Config copy, so lazy-lock.json writes land in the sandbox.
mkdir -p "$run_root/config"
cp -R "$nvim_config_src" "$run_root/config/nvim"

# Fixtures: a git repo (tracked, nested and gitignored files) and a plain dir.
gitproj="$run_root/gitproj"
plaindir="$run_root/plaindir"
mkdir -p "$gitproj/sub" "$plaindir"
printf 'int a;\n' >"$gitproj/a.c"
printf 'int b;\n' >"$gitproj/sub/b.c"
printf 'noise\n' >"$gitproj/junk.log"
printf 'junk.log\n' >"$gitproj/.gitignore"
printf 'int c;\n' >"$plaindir/c.c"
git -C "$gitproj" init -q .
git -C "$gitproj" add -A
git -C "$gitproj" -c user.email=t@t -c user.name=t commit -qm init

# fake-ctags shadows any real ctags so the index is byte-identical everywhere.
mkdir -p "$run_root/bin"
cp "$here/fixtures/fake-ctags" "$run_root/bin/ctags"
chmod +x "$run_root/bin/ctags"

specs=()
if [ "$#" -gt 0 ]; then
    for name in "$@"; do specs+=("$here/${name%_spec}_spec.lua"); done
else
    while IFS= read -r -d ''; do specs+=("$REPLY"); done \
        < <(find "$here" -maxdepth 1 -name '*_spec.lua' -print0 | sort -z)
fi

overall=0
for spec in "${specs[@]}"; do
    name="$(basename "$spec" _spec.lua)"
    if [ ! -f "$spec" ]; then
        echo "FAIL  $name -- no such spec" >&2
        overall=1
        continue
    fi
    # Fresh state per spec, shared plugin cache across specs.
    state="$run_root/state/$name"
    mkdir -p "$state"
    out="$run_root/$name.out"
    if PATH="$run_root/bin:$PATH" \
        XDG_CONFIG_HOME="$run_root/config" \
        XDG_DATA_HOME="$cache_root/data" \
        XDG_STATE_HOME="$state" \
        XDG_CACHE_HOME="$state/cache" \
        NVIM_TEST_GITPROJ="$gitproj" \
        NVIM_TEST_PLAINDIR="$plaindir" \
        nvim --headless \
        --cmd "set noswapfile" \
        --cmd "luafile $run_root/config/nvim/tests/preamble.lua" \
        -c "luafile $run_root/config/nvim/tests/${name}_spec.lua" \
        >"$out" 2>&1; then
        echo "PASS  $name -- $(grep -o '[0-9]* checks passed' "$out" | tail -1)"
    else
        overall=1
        echo "FAIL  $name"
        # Only the spec's own report, not lazy's clone chatter.
        grep -E '^( *FAIL|nvim:| *got:)' "$out" || tail -20 "$out"
    fi
done

exit "$overall"
