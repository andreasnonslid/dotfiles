#!/usr/bin/env bash

MODE="list"
usage() {
    cat <<EOF
Usage: $(basename "$0") [-w|--write] [-l|--list]
  -w, --write   format files in place
  -l, --list    list files that need formatting (default)
EOF
    exit 1
}

while (($#)); do
    case "$1" in
    -w | --write)
        MODE="write"
        shift
        ;;
    -l | --list)
        MODE="list"
        shift
        ;;
    -h | --help) usage ;;
    *)
        echo "Unknown: $1"
        usage
        ;;
    esac
done

if [ "$MODE" = "list" ]; then
    SHFMT_OPTS="-l"
    LUA_OPTS=" --check"
    BLACK_OPTS="--check --quiet"
    TAPLO_OPTS="format --check"
    CLANG_OPTS="--dry-run --Werror"
    PRETTIER_OPTS="-l"
else
    SHFMT_OPTS="-w"
    LUA_OPTS=""
    BLACK_OPTS="--quiet"
    TAPLO_OPTS="format"
    CLANG_OPTS="-i"
    PRETTIER_OPTS="--write"
fi

# Exclude only .git directories
PRUNE_ARGS=(-path '*/.git/*' -prune -o)

# Shell scripts (shfmt)
find . "${PRUNE_ARGS[@]}" -type f \( -iname '*.sh' -o -iname '*.bash' -o -iname '*.zsh' \) -print0 |
    xargs -0 shfmt $SHFMT_OPTS

# Lua files (stylua)
find . "${PRUNE_ARGS[@]}" -type f -iname '*.lua' -print0 |
    xargs -0 stylua $LUA_OPTS

# Python files (black)
find . "${PRUNE_ARGS[@]}" -type f -iname '*.py' -print0 |
    xargs -0 black $BLACK_OPTS

# TOML files (taplo)
find . "${PRUNE_ARGS[@]}" -type f -iname '*.toml' -print0 |
    xargs -0 taplo format $TAPLO_OPTS

# C/C++/Java files (clang-format)
find . "${PRUNE_ARGS[@]}" -type f \( -iname '*.c' -o -iname '*.cpp' -o -iname '*.h' -o -iname '*.hpp' -o -iname '*.java' \) -print0 |
    xargs -0 clang-format $CLANG_OPTS

# JS/TS/JSON/MD/YAML files (prettier)
find . "${PRUNE_ARGS[@]}" -type f \( -iname '*.js' -o -iname '*.jsx' -o -iname '*.ts' -o -iname '*.tsx' -o -iname '*.json' -o -iname '*.md' -o -iname '*.yaml' -o -iname '*.yml' \) -print0 |
    xargs -0 prettier $PRETTIER_OPTS

