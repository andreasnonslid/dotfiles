#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use --lts >/dev/null

DO_INSTALL=0
MODE="-l"

usage(){
  cat <<EOF
Usage: $(basename "$0") [--install|-i] [--write|-w] [--list|-l]
  -i, --install   npm install --global prettier and its plugins
  -w, --write     run prettier --write (in-place)
  -l, --list      run prettier -l (list unformatted; default)
EOF
  exit 1
}

while (( $# )); do
  case $1 in
    -i|--install) DO_INSTALL=1; shift ;;
    -w|--write)    MODE="--write"; shift ;;
    -l|--list)     MODE="-l"; shift ;;
    -h|--help)     usage ;;
    *)             echo "Unknown option: $1" >&2; usage ;;
  esac
done

if (( DO_INSTALL )); then
  echo "🔧 Installing prettier & plugins globally…"
  npm install --global \
    prettier \
    prettier-plugin-lua \
    prettier-plugin-shell \
    prettier-plugin-toml \
    prettier-plugin-fish
  echo "✅ Installed."
fi

echo "💅 Running: find . -type d -name .git -prune -o -type f -print0 | xargs -0 prettier ${MODE} --ignore-path '' --ignore-unknown"
find . \
  -type d -name .git -prune \
  -o -type f -print0 \
| xargs -0 prettier $MODE --ignore-path '' --ignore-unknown

echo "🎉 Done."

