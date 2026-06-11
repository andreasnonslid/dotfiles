# Useful things to remember

choco install iosevka-nerd-font

choco install tree-sitter

Details: (https://community.chocolatey.org/packages?q=iosevka)

pip install neovim

npm install -g neovim

# Dotfiles

## Setup (new machine)

```sh
git clone git@github.com:andreasnonslid/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

`bootstrap.sh` is idempotent. It:

1. Runs `configure_git.sh` (sets `core.autocrlf`, enables commit-msg hooks).
2. Runs `symlink.py -y` — links bashrc, nvim, configs, starship, and the
   always-on **caveman** rule into `~/.cursor/rules/caveman.mdc` (Cursor IDE +
   CLI) and `~/.claude/CLAUDE.md` (Claude Code).
3. Reminds you about machine-local secrets in `~/.local/secrets/` (never
   tracked; linked in automatically when present).

### Secrets

Secrets stay out of git in `~/.local/secrets/`. Example:

```sh
mkdir -p ~/.local/secrets/autostore
echo 'export GITLAB_ACCESS_KEY=...' > ~/.local/secrets/autostore/gitlab-npm.env
./bootstrap.sh   # re-run to link it into ~/.config/autostore/
```

## Commit Message Enforcement

This repository enforces a professional commit message style using a portable Perl commit-msg hook stored in `.githooks/commit-msg`.

**Commit message format:**

- `<type>(optional-scope): <summary>`
- Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- Type: lower-case, required
- Scope: optional, lower-case, no spaces
- Summary: 2-10 words, 10-50 characters
- Header: max 72 characters

---
