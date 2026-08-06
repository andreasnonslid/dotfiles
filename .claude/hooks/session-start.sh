#!/usr/bin/env bash
# SessionStart hook: runs scripts/setup-agent-env.sh on Claude Code on the
# web so shellcheck/shfmt/stylua/taplo/lua/zsh and core.hooksPath are ready
# before any agent work starts. No-op outside the remote web environment.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
    exit 0
fi

"$CLAUDE_PROJECT_DIR/scripts/setup-agent-env.sh"
