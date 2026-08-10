# Dotfiles

Personal + work dev environment: shell config, nvim, git/SSH identity, terminal and
toolchain setup. Supports **macOS** (Apple Silicon), **Linux** (Ubuntu, Debian, Arch,
openSUSE, including WSL) and **Windows**, from a single clone.

## Setup

```sh
git clone git@github.com:andreasnonslid/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

`bootstrap.sh` is idempotent — safe to re-run. It:

1. Runs `configure_git.sh` (`core.autocrlf` + `core.hooksPath` for the commit-msg hook).
2. **On macOS**: runs `macos/install.sh` first — Xcode Command Line Tools, Homebrew,
   `brew bundle` against `macos/Brewfile` + `macos/Brewfile.casks`, then
   `macos/defaults.sh`. See `macos/RUNBOOK.md` for the full day-one sequence, including
   the permission grants (Accessibility, Input Monitoring) that AeroSpace, Karabiner
   and Raycast need and that nothing can script.
   **On Linux/WSL**: package installation is a separate, manual step — run the script
   for your distro first (`linux/ubuntu.sh`, `linux/debian.sh`, `linux/arch.sh`,
   `linux/opensuse.sh`), then `bootstrap.sh` only symlinks.
3. Runs `symlink.py -y` — links bashrc/zshrc (including the tracked `.gitconfig` and
   `~/.ssh/config`), nvim, terminal/editor configs, starship, and the always-on
   **caveman** rule into `~/.cursor/rules/caveman.mdc` (Cursor IDE + CLI) and
   `~/.claude/CLAUDE.md` (Claude Code). The link set is OS-aware — e.g. Ghostty and
   AeroSpace configs link only on darwin, Hyprland/waybar only on Linux.
4. Reminds you about machine-local secrets in `~/.local/secrets/` (never tracked;
   linked in automatically when present).

### Windows

Native Windows setup is a standalone PowerShell script, not part of `bootstrap.sh`:

```powershell
windows/initial_install.ps1
```

It installs [Chocolatey](https://chocolatey.org/) plus the CLI toolset (git, ripgrep,
fd, bat, zoxide, starship, neovim, ...), pyenv-win, nvm-windows, rustup and xpm. Two
packages worth calling out that the script doesn't cover:

```powershell
choco install iosevka-nerd-font tree-sitter
```

(details: <https://community.chocolatey.org/packages?q=iosevka>), plus the Python/Node
neovim providers:

```sh
pip install neovim
npm install -g neovim
```

`windows/` also holds WezTerm config (`wezterm.lua`, `wezterm-mouse-buttons.ahk`),
GlazeWM config (`glazewm-config.yaml`, `glazewm-setup.md`) and a PuTTY-in-WSL guide
(`setup_putty_in_wsl.md`).

## Shell architecture

Hybrid: an OS-agnostic core plus thin per-shell adapters, so the same aliases,
functions and tool wiring work whether the login shell is bash (Linux/WSL) or zsh
(macOS).

- `bashrc/.shell_modules/core/` — shared settings, aliases and functions. Must parse
  under both `bash -n` and `zsh -n`; no bashisms.
- `bashrc/.shell_modules/bash/` — bash-only surface: the `bind`/`shopt`/readline block
  and bash-completion (`__git_complete` for ~45 git aliases).
- `bashrc/.shell_modules/zsh/` — zsh equivalents, including `compdef`-based completion
  for the same aliases.
- `bashrc/.shell_modules/git/`, `tools/`, `toolchains/`, `scripts/` — OS-agnostic
  git aliases, tool wrappers (e.g. the `clip`/`paste` clipboard abstraction that
  dispatches to `pbcopy`/`pbpaste`, `wl-copy`/`wl-paste`, `xclip`, or `clip.exe` under
  WSL) and misc shell functions.
- `bashrc/.bashrc` — Linux/WSL login shell entrypoint.
- `bashrc/.zshrc` — macOS login shell entrypoint. Sources `core` → `git` → `tools` →
  `zsh/`, wires up starship, zoxide and mise.

Prompt is [starship](https://starship.rs) (`starship.toml`) on both shells — no
hand-rolled `PROMPT_COMMAND`/PS1 parsing.

`lib/os.sh` (pure POSIX `sh`, sourceable from bash/zsh/`.profile`) provides
`detect_os`, `detect_arch`, `is_macos`, `is_linux`, `is_wsl` — every OS-conditional
piece of shell config and every provisioning script is built on these rather than
ad hoc `uname` checks.

### Secrets

Secrets stay out of git in `~/.local/secrets/`. Example:

```sh
mkdir -p ~/.local/secrets/autostore
echo 'export GITLAB_ACCESS_KEY=...' > ~/.local/secrets/autostore/gitlab-npm.env
./bootstrap.sh   # re-run to link it into ~/.config/autostore/
```

This same scheme carries the work GitLab npm token: `GITLAB_ACCESS_KEY` from
`gitlab-npm.env` is sourced by the active shell init (`bashrc/.bashrc` or
`bashrc/.zshrc`) and consumed by `~/.npmrc`'s `_authToken=${GITLAB_ACCESS_KEY}` line
for the `@autostore`-scoped registry. `~/.npmrc` itself is **not** tracked here — its
registry URL and scope are set up per your team's npm docs, same as any other
machine-specific `.npmrc`.

**macOS:** this scheme needs no changes. `symlink.py`'s `secret_links` and
`secrets_root` lookup use `pathlib` exclusively with no OS-specific branches, so the
instructions above apply as-is. Plain files in `~/.local/secrets/` (rather than macOS
Keychain) remain the right call here too: it's the same mechanism already used for git
identity and SSH host config below, so there's one place to look across every OS
instead of a Mac-only exception.

### Git identity

`.gitconfig` is tracked (symlinked to `~/.gitconfig`), so it deliberately has no
`[user]` section — a hardcoded name/email would leak into commit history. It includes
identity from machine-local files instead, one for the default (personal) identity and
one that overrides it for anything cloned under `~/work/`:

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

Clone work repos under `~/work/` so the `includeIf "gitdir:~/work/"` rule picks up the
work identity automatically; everything else falls back to the personal one. Missing
files are silently ignored by git (no identity set, not an error) — `./scripts/doctor.sh`
flags that instead of leaving it to a failed commit to surface it.

### SSH config

`~/.ssh/config` is tracked the same way — no host- or identity-specific entries live
in it, only defaults. Per-host blocks (git hosts, VPN jump hosts, ...) go in
`~/.local/secrets/ssh/*.conf` instead, pulled in via an `Include` line. Use
`ssh/setup_git_host.sh <host> <key-domain>` to add one — it picks the right key by
matching `<key-domain>` against each `~/.ssh/*.pub` comment. On macOS, key passphrases
are also kept in the login Keychain (`UseKeychain`) via `~/.ssh/config.darwin`, linked
in only on darwin since that keyword doesn't exist outside Apple's OpenSSH fork.

### Toolchains (mise)

`mise` replaces `pyenv` + `nvm` on macOS and Linux. Global versions are pinned in
`bashrc/.config/mise/config.toml` (symlinked to `~/.config/mise/config.toml`) rather
than left to drift per distro script, which is what happened before M23:
Ubuntu/Debian/openSUSE pyenv-globaled 3.13.0, Arch pyenv-globaled 3.11.13, and every
script ran `nvm install --lts` — a floating alias that silently changes meaning each
time a new Node line goes Active LTS. `rustup`/`~/.cargo/env` is unaffected; mise adds
nothing there. (Windows keeps pyenv-win + nvm-windows for now — see the Windows
section above.)

Add or bump a global tool:

```sh
mise use -g node@22        # edits ~/.config/mise/config.toml in place
mise install                # actually downloads the pinned versions
```

Commit the resulting change to `bashrc/.config/mise/config.toml` so every machine
picks it up on the next `git pull`.

`xpm` (used by `compilers/arm_gcc.sh` and `macos/embedded.sh` for the ARM toolchain,
M25) stays a plain `npm install --global xpm` rather than moving under mise's npm
backend — it needs to be resolvable regardless of which Node version mise has active,
and folding it in is a separate change to those scripts, out of scope here.

## Verification

Two scripts, two different jobs — run the right one for what you're checking:

| Tool                  | Runs where              | Runs when              | Answers                                                                                                                                                                                                               |
| --------------------- | ----------------------- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `./scripts/check.sh`  | Any dev machine / CI    | Before every commit    | "Is the repo internally consistent?" — shellcheck, `bash -n`/`zsh -n`, `stylua --check`, the symlink pytest suite, `lua pretty.lua -l`.                                                                               |
| `./scripts/doctor.sh` | The real target machine | Day one, and on demand | "Does _this_ machine actually work?" — runtime diagnostics (auto-discovered checks under `scripts/doctor.d/`), each `PASS`/`WARN`/`FAIL` with a remediation hint. Supports `--verbose`, `--json`, `--only <section>`. |

`check.sh` can't see whether Homebrew installed correctly or whether AeroSpace has its
Accessibility grant — that's what `doctor.sh` is for. `doctor.sh` runs both pre-flight
(on a bare machine, to see what's missing before `bootstrap.sh`) and post-flight (as
the acceptance gate after). See `macos/RUNBOOK.md` for the full day-one macOS sequence
built around both scripts.

`--json` is the machine-readable form of `doctor.sh`'s output, meant to be handed back
to an agent rather than read by a human: run `./scripts/doctor.sh --json`, save the
output, and pass it along to drive M36, the final reconciliation that folds real-hardware
findings back into the scripts. See step 10 of `macos/RUNBOOK.md` for the exact command.

## Agent / formatter tooling

`.githooks/pre-commit` runs `lua pretty.lua -l`, which needs `shellcheck`, `shfmt`,
`stylua`, `taplo` and `lua` itself on `PATH`. Claude Code on the web installs these
automatically via a `SessionStart` hook (`.claude/hooks/session-start.sh`). To set up
the same tooling by hand (e.g. on a fresh Debian/Ubuntu container or machine):

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
