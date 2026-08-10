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

1. Runs `configure_git.sh` (enables commit-msg hooks via `core.hooksPath`).
2. Runs `symlink.py -y` — links bashrc (including the tracked `.gitconfig`),
   nvim, configs, starship, and the always-on **caveman** rule into
   `~/.cursor/rules/caveman.mdc` (Cursor IDE + CLI) and `~/.claude/CLAUDE.md`
   (Claude Code).
3. Reminds you about machine-local secrets in `~/.local/secrets/` (never
   tracked; linked in automatically when present).

### Secrets

Secrets stay out of git in `~/.local/secrets/`. Example:

```sh
mkdir -p ~/.local/secrets/autostore
echo 'export GITLAB_ACCESS_KEY=...' > ~/.local/secrets/autostore/gitlab-npm.env
./bootstrap.sh   # re-run to link it into ~/.config/autostore/
```

This same scheme carries the work GitLab npm token: `GITLAB_ACCESS_KEY` from
`gitlab-npm.env` is sourced by the active shell init (`bashrc/.bashrc`
today) and consumed by `~/.npmrc`'s `_authToken=${GITLAB_ACCESS_KEY}` line
for the `@autostore`-scoped registry. `~/.npmrc` itself is **not** tracked
here — its registry URL and scope are set up per your team's npm docs, same
as any other machine-specific `.npmrc`.

**macOS:** this scheme needs no changes. `symlink.py`'s `secret_links` and
`secrets_root` lookup use `pathlib` exclusively with no OS-specific
branches, so the instructions above apply as-is. Plain files in
`~/.local/secrets/` (rather than macOS Keychain) remain the right call
here too: it's the same mechanism already used for git identity and SSH
host config below, so there's one place to look across every OS instead of
a Mac-only exception.

### Git identity

`.gitconfig` is tracked (symlinked to `~/.gitconfig`), so it deliberately has
no `[user]` section — a hardcoded name/email would leak into commit history.
It includes identity from machine-local files instead, one for the default
(personal) identity and one that overrides it for anything cloned under
`~/work/`:

```sh
mkdir -p ~/.local/secrets/git
cat > ~/.local/secrets/git/personal.gitconfig <<'EOF'
[user]
    name = Your Name
    email = you@example.com
EOF

cat > ~/.local/secrets/git/work.gitconfig <<'EOF'
[user]
    name = Your Name
    email = you@work-domain.com
EOF
```

Clone work repos under `~/work/` so the `includeIf "gitdir:~/work/"` rule
picks up the work identity automatically; everything else falls back to the
personal one. Missing files are silently ignored by git (no identity set,
not an error) — `./scripts/doctor.sh` flags that instead of leaving it to a
failed commit to surface it.

### SSH config

`~/.ssh/config` is tracked the same way — no host- or identity-specific
entries live in it, only defaults. Per-host blocks (git hosts, VPN jump
hosts, ...) go in `~/.local/secrets/ssh/*.conf` instead, pulled in via an
`Include` line. Use `ssh/setup_git_host.sh <host> <key-domain>` to add one —
it picks the right key by matching `<key-domain>` against each
`~/.ssh/*.pub` comment. On macOS, key passphrases are also kept in the login
Keychain (`UseKeychain`) via `~/.ssh/config.darwin`, linked in only on
darwin since that keyword doesn't exist outside Apple's OpenSSH fork.

### Toolchains (mise)

`mise` replaces `pyenv` + `nvm`. Global versions are pinned in
`bashrc/.config/mise/config.toml` (symlinked to
`~/.config/mise/config.toml`) rather than left to drift per distro script,
which is what happened before M23: Ubuntu/Debian/openSUSE pyenv-globaled
3.13.0, Arch pyenv-globaled 3.11.13, and every script ran `nvm install --lts`
— a floating alias that silently changes meaning each time a new Node line
goes Active LTS. `rustup`/`~/.cargo/env` is unaffected; mise adds nothing
there.

Add or bump a global tool:

```sh
mise use -g node@22        # edits ~/.config/mise/config.toml in place
mise install                # actually downloads the pinned versions
```

Commit the resulting change to `bashrc/.config/mise/config.toml` so every
machine picks it up on the next `git pull`.

`xpm` (used by `compilers/arm_gcc.sh` and `macos/embedded.sh` for the ARM
toolchain, M25) stays a plain `npm install --global xpm` rather than moving
under mise's npm backend — it needs to be resolvable regardless of which
Node version mise has active, and folding it in is a separate change to
those scripts, out of scope here.

## Agent / formatter tooling

`.githooks/pre-commit` runs `lua pretty.lua -l`, which needs `shellcheck`,
`shfmt`, `stylua`, `taplo` and `lua` itself on `PATH`. Claude Code on the web
installs these automatically via a `SessionStart` hook
(`.claude/hooks/session-start.sh`). To set up the same tooling by hand (e.g.
on a fresh Debian/Ubuntu container or machine):

```sh
./scripts/setup-agent-env.sh
```

It's idempotent — safe to re-run, and skips anything already installed.

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
