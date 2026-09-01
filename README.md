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
  and `completion.sh` (`__git_complete` for ~45 git aliases). That file lived in
  `tools/` until it was noticed that zsh sourced it from the shared loop and printed
  `command not found: shopt` on every macOS shell start.
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
| `./scripts/check.sh`  | Any dev machine / CI    | Before every commit    | "Is the repo internally consistent?" — shellcheck, `bash -n`/`zsh -n`, `stylua --check`, the pytest suites (symlinks, shell startup, usage tracking), the nvim config tests, `lua pretty.lua -l`.                     |
| `./scripts/doctor.sh` | The real target machine | Day one, and on demand | "Does _this_ machine actually work?" — runtime diagnostics (auto-discovered checks under `scripts/doctor.d/`), each `PASS`/`WARN`/`FAIL` with a remediation hint. Supports `--verbose`, `--json`, `--only <section>`. |

`bash -n`/`zsh -n` only prove the shell files _parse_. What actually breaks is a
module that parses but errors while sourcing, or drifts between the two shells --
so `tests/test_shell_startup.py` starts a real interactive shell of each kind
against a staged `HOME` and asserts the things syntax cannot: startup is silent on
stderr, `PATH` has no duplicate entries, the `core/` surface is live, and every
shared shortcut exists in _both_ shells. It found the two bugs above on its first
run.

`check.sh` can't see whether Homebrew installed correctly or whether AeroSpace has its
Accessibility grant — that's what `doctor.sh` is for. `doctor.sh` runs both pre-flight
(on a bare machine, to see what's missing before `bootstrap.sh`) and post-flight (as
the acceptance gate after). See `macos/RUNBOOK.md` for the full day-one macOS sequence
built around both scripts.

`--json` is the machine-readable form of `doctor.sh`'s output, meant to be handed back
to an agent rather than read by a human: run `./scripts/doctor.sh --json`, save the
output, and pass it along to drive M36, the final reconciliation that folds real-hardware
findings back into the scripts. See step 10 of `macos/RUNBOOK.md` for the exact command.

## Shortcut usage tracking

This repo declares ~126 aliases and functions. Nobody remembers which of those
they still use, and guessing produces the two usual outcomes: deleting something
load-bearing, or keeping everything forever. So usage is measured instead.

`bashrc/.shell_modules/core/usage_tracking.sh` loads automatically in both shells
(it lives in `core/`, which `.bashrc` and `.zshrc` both source) and appends one
TSV line per command: `epoch`, shell, command.

**It records the first word only, never arguments.** Arguments here routinely
carry Jira ticket ids, ssh key names, hostnames and absolute paths, and none of
that is needed to answer "do I still use this alias?". A shell history quietly
duplicated into a second file is a liability nobody asked for.
`tests/test_usage_tracking.py` asserts this against both shells, with real
secret-shaped strings.

The log lives at `~/.local/state/dotfiles/usage.tsv`, deliberately outside the
repo: inside a git work tree it would dirty `git status` on every command and
put the pre-commit hook in a fight with the shell.

```sh
export DOTFILES_USAGE_TRACK=0                    # opt out entirely
export DOTFILES_USAGE_LOG=/some/other/path.tsv   # or move it
```

Mechanism differs by shell because bash has no `preexec`: zsh uses the real hook,
bash reads the last history entry at the next prompt. The bash path therefore
records one command per prompt, so a compound line (`a; b`) logs only `a` --
which is fine for the question being asked, and far cheaper than a `DEBUG` trap
firing per pipeline element.

### Reading the results

```sh
./scripts/usage-report.sh              # summary + what has never been used
./scripts/usage-report.sh --used       # what has, by frequency
./scripts/usage-report.sh --all
./scripts/usage-report.sh --json       # for an agent
./scripts/usage-report.sh --dead-files # static: files nothing references
```

`doctor.sh` reports the summary under its `usage` section and starts nagging
about unused shortcuts once there are 30+ days of data. Below 14 days the report
says so outright — a shortcut unused for three days is not evidence.

Names declared more than once are counted once: `ff`/`ll`/`la` each have two
declarations because `tools/search.sh` and `tools/eza.sh` define them in
`if`/`else` fallback branches (fd vs find, eza vs ls). That is not duplication to
clean up, and the report marks it `(+1 more)` rather than inflating the totals.

## Tests

`./scripts/check.sh` runs everything in ~17s. Four suites, split by what they
need to run inside:

| Suite          | Lives in                       | Runs in                           | Covers                                                                                 |
| -------------- | ------------------------------ | --------------------------------- | -------------------------------------------------------------------------------------- |
| symlinks       | `tests/test_symlink.py`        | pytest                            | the exact link set `symlink.py` produces, per OS                                       |
| shell startup  | `tests/test_shell_startup.py`  | pytest, real `bash -i` / `zsh -i` | rc files source silently, no duplicate `PATH`, `core/` surface live, both shells agree |
| usage tracking | `tests/test_usage_tracking.py` | pytest, both shells               | the logger records names and never arguments; the report's maths                       |
| repo contracts | `tests/test_repo_contracts.py` | pytest                            | pairs that drift quietly: the inventory floor, every `doctor.d` module still reporting |
| nvim config    | `nvim/tests/*_spec.lua`        | headless Neovim                   | plugins load, keymaps hold, lockfile pinned, tags and diff behave                      |

### What is covered without writing a test

Most additions are picked up by an existing assertion, which is the point:

- **A plugin** — `config_spec` asserts every plugin in the lazy spec is installed
  and loads clean; `lockfile_spec` asserts it is pinned to a full sha.
- **An LSP server** — `config.lsp` returns its server list, and `config_spec`
  checks it against `lsp/*.lua` in both directions. A config file with no entry,
  or an entry with no file, fails.
- **An alias or function in `core/`, `git/` or `tools/`** — the shell-startup
  suite requires it to resolve in _both_ shells, and usage tracking starts
  counting it.
- **An alias in `.bashrc` or `.zshrc`** — actively rejected. Shared shortcuts
  belong in `core/`, shell-specific ones in `bash/` or `zsh/`.
- **A `doctor.d` check** — must report at least one result, or it counts as a
  silent hole.

### What still needs one

Behaviour beyond "it loads": a new module's actual logic, a new script's
contract. Add a `*_spec.lua` under `nvim/tests/` (the harness is `tests/init.lua`
— `t.check(name, ok, detail)`, `t.finish()`, and `run.sh` discovers it), or a
`test_*.py` under `tests/`.

**Write the test so it fails first.** Every check in these suites was confirmed
against a deliberately broken config before being kept — a test that has never
failed is a test that has never been shown to work.

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
