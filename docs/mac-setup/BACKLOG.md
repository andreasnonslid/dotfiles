# Mac Work Setup — Epics & Agent Backlog

Source-of-truth backlog for bringing macOS support to this repo. One deliverable per
agent run. Tick the box, close the issue, stop.

**Progress: 4 / 45 complete**

## Context

A new work MacBook (Apple Silicon, full admin, unrestricted) is arriving. This repo
currently has **zero macOS support** — an exhaustive grep for
`darwin|macos|osx|brew|aerospace|yabai` returns two incidental hits (a commented-out
`pbcopy` line in the vendored zellij config, and a Windows-vs-everything-else check in
`nvim/lua/plugins/floating-term.lua`).

Today the repo supports Ubuntu, Debian, Arch, openSUSE and Windows/WSL. `bootstrap.sh`
only symlinks; package installation lives in per-distro scripts under `linux/`. The goal
is a fully working Mac from a single clone + bootstrap, without regressing the Linux and
Windows setups that are in daily use.

### The hard constraint that shapes everything

**The agents run in a Linux container and cannot test on macOS.** Every deliverable must
be _statically_ verifiable — syntax checks, shellcheck, a symlink-map unit test against a
fake `$HOME`. Anything genuinely requiring the physical machine is tagged `needs-mac`,
routed to `macos/RUNBOOK.md`, and reconciled in M36.

The corollary: because the agents work blind, the machine needs a way to report back.
That is `scripts/doctor.sh` (epic E10) — runtime diagnostics run on the Mac that say
exactly what works and what doesn't. Deliberately separate from `check.sh`, hoisted early
so every epic registers its own checks as it lands, and its `--json` output drives the
final reconciliation.

### Two verification tools, different jobs

| Tool                | Runs where       | Runs when              | Answers                              |
| ------------------- | ---------------- | ---------------------- | ------------------------------------ |
| `scripts/check.sh`  | Linux container  | Before every commit    | "Is the repo internally consistent?" |
| `scripts/doctor.sh` | The real machine | Day one, and on demand | "Does this machine actually work?"   |

### Decisions already made

| Area        | Decision                                                                                    |
| ----------- | ------------------------------------------------------------------------------------------- |
| Shell       | **Hybrid.** Agnostic core + thin `bash/` and `zsh/` adapters. Mac runs zsh; WSL keeps bash. |
| Prompt      | **Starship.** Delete the hand-rolled `PROMPT_COMMAND` PS1.                                  |
| Terminal    | **Ghostty**                                                                                 |
| Window mgmt | **AeroSpace + Raycast** (skip yabai — needs SIP disabled)                                   |
| Toolchains  | **mise** replaces pyenv + nvm. `rustup` stays independent.                                  |
| Embedded    | **Yes, same work.** xpm-primary ARM toolchain, brew cask as fallback.                       |

### Why the shell migration is affordable

Of ~2,851 lines of shell config, the genuinely bash-only surface is roughly **150 lines**
in three places: the `bind`/`shopt` block in `core/settings.sh`, all of
`tools/completion.sh` (bash-completion + `__git_complete` for ~45 git aliases), and the
custom PS1 in `.bashrc`. `git/aliases.sh` (307 lines) is nearly all plain `alias` lines
that work verbatim in zsh; the `tools/*.sh` functions are POSIX-ish. Even `declare -gA`
in `core/fn_wrapper.sh` works in zsh (`declare` is `typeset`). Starship deletes the
largest bash-specific chunk and is a win regardless.

---

## Issue index

Every deliverable has a GitHub issue. Claim it by commenting before starting work.

| ID  | Issue | ID  | Issue | ID  | Issue |
| --- | ----- | --- | ----- | --- | ----- |
| M00 | #7    | M13 | #28   | M26 | #41   |
| M01 | #8    | M14 | #29   | M27 | #42   |
| M02 | #9    | M15 | #30   | M28 | #43   |
| M03 | #10   | M16 | #31   | M29 | #44   |
| M04 | #11   | M17 | #32   | M30 | #45   |
| M05 | #12   | M18 | #33   | M31 | #46   |
| D01 | #13   | M19 | #34   | M32 | #47   |
| D02 | #14   | M20 | #35   | M33 | #48   |
| D03 | #15   | M21 | #36   | M34 | #49   |
| D04 | #16   | M22 | #37   | M35 | #50   |
| D05 | #17   | M23 | #38   | M36 | #51   |
| D06 | #18   | M24 | #39   |     |       |
| D07 | #19   | M25 | #40   |     |       |
| D08 | #20   |     |       |     |       |
| M06 | #21   |     |       |     |       |
| M07 | #22   |     |       |     |       |
| M08 | #23   |     |       |     |       |
| M09 | #24   |     |       |     |       |
| M10 | #25   |     |       |     |       |
| M11 | #26   |     |       |     |       |
| M12 | #27   |     |       |     |       |

---

## Legend

- `[dep: …]` — blocked until those IDs are ticked
- `needs-mac` — cannot be verified in the container; write it, add a RUNBOOK entry, user
  validates on hardware

---

## E0 — Foundation: make the repo OS-aware

_Blocks everything._

- [x] **M00 — Agent environment setup**
      The container is missing `shfmt`, `stylua`, `taplo`, `lua`, `shellcheck` and `zsh`,
      so M02's harness would have nothing to run and `pretty.lua` silently skips those
      formatters. Add a `SessionStart` hook (or `scripts/setup-agent-env.sh`) that
      installs them. **Verify `lua` specifically** — `.githooks/pre-commit` hard-depends on
      it and fails closed, blocking every commit, which is silent and confusing. Also
      confirm `core.hooksPath` gets set; it is currently unset in fresh clones.

- [x] **M01 — `lib/os.sh`**
      `detect_os` (darwin/linux/windows), `detect_arch`, `is_macos`, `is_linux`, `is_wsl`.
      Pure POSIX sh, no bashisms. Sourceable from bash _and_ zsh. `shellcheck` clean.
      [dep: M00]

- [x] **M02 — `scripts/check.sh` static harness**
      Runs `shellcheck` on all `.sh`, `bash -n`/`zsh -n` syntax checks, `stylua --check`,
      `python3 -m pytest` on the symlink tests, and `lua pretty.lua -l`. Exits non-zero on
      any failure. **This is what every subsequent agent runs before committing.**
      [dep: M00]

- [ ] **M03 — Per-OS link manifest in `symlink.py`**
      Darwin branch. `hypr/`, `waybar/`, `mako/`, `mimeapps.list` excluded on darwin;
      Ghostty/AeroSpace included only on darwin. Preserve the existing "never symlink
      `~/.config` wholesale" safety property. [dep: M01]

- [ ] **M04 — `tests/test_symlink.py`**
      Run `symlink.py` against a temp fake `$HOME` with the platform monkeypatched to
      darwin _and_ linux; assert the exact expected link set for each. Wire into
      `check.sh`. [dep: M03]

- [ ] **M05 — `bootstrap.sh` OS dispatch**
      Source `lib/os.sh`; on darwin run `macos/install.sh`, on linux keep current
      behaviour. Still idempotent. Fail loudly with a clear message on unsupported OS.
      [dep: M01]

---

## E10 — Diagnostics (`scripts/doctor.sh`)

_D01 is hoisted to run immediately after M02_, so every later epic registers its own
checks as it lands rather than bolting diagnostics on at the end. `doctor.sh` must run
**before** bootstrap (pre-flight: "what's missing?") as well as after (post-flight: "did
it work?").

- [x] **D01 — `scripts/doctor.sh` framework + core checks**
      Check-registration pattern with auto-discovered modules in `scripts/doctor.d/`. Each
      check emits `PASS`/`WARN`/`FAIL` plus a remediation hint. Grouped output, colour when
      TTY, summary counts, non-zero exit on any FAIL. Flags: `--verbose`, `--json`
      (machine-readable, for agents to parse), `--only <section>`. Must **degrade
      gracefully when things are missing** — that is the pre-flight use case, not a crash.
      Core checks: OS + arch (flag Rosetta/x86 emulation explicitly), PATH sanity,
      `$DOTFILES` resolution. [dep: M02]

- [ ] **D02 — Symlink integrity check**
      Every link `symlink.py` should have created exists, is a symlink, and resolves _into
      the repo_. Explicitly detect dangling links and files silently `.bak`-ed during
      bootstrap — the current backup behaviour is easy to miss. [dep: D01, M03]

- [ ] **D03 — Toolchain & binary presence check**
      Every assumed binary, with version reported — git, nvim, rg, fd, bat, eza, zoxide,
      fzf, jq, just, zellij, starship, gh, mise, lua. **Separately assert every formatter
      the pre-commit hook needs** (shfmt, stylua, black, taplo, prettier, clang-format,
      lua) and assert `core.hooksPath` is set. [dep: D01, M14]

- [ ] **D04 — Shell health check**
      Login shell is the intended one; every `.shell_modules` file sources without error;
      the alias + function inventory matches a committed expected list (catches a module
      silently failing to load); starship, zoxide and mise all initialise; `clip`/`paste`
      survive a round-trip. [dep: D01, M08, M09]

- [ ] **D05 — Editor & git identity check**
      `nvim --headless "+checkhealth" +qa` parsed for errors; lazy.nvim plugins installed;
      each `lsp/*.lua` server binary resolvable. Git: correct identity resolves inside a
      work path vs a personal path (proves the M29 `includeIf` split works — a wrong-email
      commit to a work repo is annoying to undo). SSH agent running with keys loaded.
      [dep: D01, M29, M32]

- [ ] **D06 — macOS-specific checks** `needs-mac`
      Homebrew present and `brew bundle check` satisfied; Iosevka Nerd Font installed;
      spot-check `defaults read` returns what `defaults.sh` wrote. **Verify AeroSpace /
      Raycast / Karabiner hold their Accessibility and Input-Monitoring grants** — these
      cannot be scripted during install and are the most common silent day-one failure.
      [dep: D01, M16, M21]

- [ ] **D07 — Embedded toolchain check** `needs-mac`
      `arm-none-eabi-gcc --version` matches the pinned xpm version; `openocd --version`;
      `probe-rs list` detects an attached probe **without sudo** — asserted explicitly,
      since non-root ST-Link access on Apple Silicon is a known pain point. Skip cleanly
      with `WARN` when no probe is plugged in. [dep: D01, M26]

- [ ] **D08 — Wire doctor into RUNBOOK and README**
      RUNBOOK's day-one sequence ends with `./scripts/doctor.sh`; README documents both
      scripts and when to use which. [dep: D01, M35]

**Standing requirement on every other deliverable:** if an item introduces something a
machine could plausibly get wrong, it also adds the matching check to `scripts/doctor.d/`.

---

## E1 — Shell: hybrid core + adapters

- [ ] **M06 — Split `.shell_modules` into agnostic core + `bash/` and `zsh/` adapters**
      Move `bind`/`shopt`/readline out of `core/settings.sh` into `bash/`. `core/` must
      parse under both `bash -n` and `zsh -n`. No behaviour change on Linux — verify the
      full alias/function list is unchanged. [dep: M02]

- [ ] **M07 — Adopt starship, delete the hand-rolled PS1**
      Remove `update_exit_status`/`parse_git_branch`/`setPS1`/`PROMPT_COMMAND` from
      `.bashrc`. Extend `starship.toml` to cover what the old prompt showed: exit-status
      glyph, cwd, git branch, clock. [dep: M06]

- [ ] **M08 — `bashrc/.zshrc`**
      Sources `core` → `git` → `tools` → `zsh/`. Wires starship, zoxide, mise. Symlinked
      by `symlink.py` on darwin. `zsh -n` clean. [dep: M06, M07]

- [ ] **M09 — `tools/clipboard.sh` — `clip`/`paste` abstraction**
      Dispatch to `pbcopy`/`pbpaste` on darwin, `wl-copy`/`wl-paste` under Wayland,
      `xclip` under X11, `clip.exe` under WSL. Replace the raw `xclip` call in
      `ssh/setup_ssh_key.sh`. [dep: M01]

- [ ] **M10 — Guard all Linux-only bits in shared config**
      `/opt/nvim-linux-x86_64` PATH entry, `STM32_PRG_PATH` (currently hardcoded to a wrong
      `/home/anh/...` path — fix or drop), `tools/wsl.sh`, zellij auto-start. Each guarded
      by `lib/os.sh` predicates, not silent failure. [dep: M01, M06]

- [ ] **M11 — Port `tools/completion.sh` to zsh compsys**
      All ~45 `__git_complete` aliases get `compdef` equivalents in `zsh/completion.sh`.
      Custom completions for `gcmp`, `rs`, `rh` preserved. Bash version stays untouched
      under `bash/`. [dep: M06]

- [ ] **M12 — Drop vendored `bashrc/z.sh`**
      Superseded by zoxide, already initialised in `.bashrc` and the `cd` override in
      `tools/navigation.sh`. Remove file, remove from link map, confirm nothing references
      it. Note `pretty.lua` has an explicit exclude for it that should also go. [dep: M06]

---

## E2 — macOS provisioning

- [ ] **M13 — `macos/install.sh` orchestrator**
      Idempotent. Installs Xcode Command Line Tools, installs Homebrew if absent, handles
      `/opt/homebrew` shellenv wiring, runs `brew bundle`, then `defaults.sh`. Safe to
      re-run. `shellcheck` clean. [dep: M05]

- [ ] **M14 — `macos/Brewfile` — CLI formulae**
      Union of the existing distro scripts — git, git-lfs, cmake, ninja, automake, jq,
      fzf, bat, ripgrep, fd, the_silver_searcher, zoxide, eza, neovim, tmux, just, llvm,
      less, lua, libgit2, gh, git-delta, sd, starship, zellij, tealdeer, go. **Must
      include every formatter `pretty.lua` and the pre-commit hook need** (shfmt, stylua,
      black, taplo, prettier, clang-format, lua) — the hook breaks on the Mac otherwise.
      [dep: M13]

- [ ] **M15 — `macos/Brewfile` — casks, fonts, GUI apps**
      `ghostty`, `nikitabobko/tap/aerospace`, `raycast`, `karabiner-elements`,
      `font-iosevka-term-nerd-font` (matches the existing Zed + WezTerm font choice), plus
      browser/editor casks. Split into a clearly-marked optional section to prune.
      [dep: M14]

- [ ] **M16 — `macos/defaults.sh` — system preferences** `needs-mac`
      Fast key repeat + short delay (essential for vim), disable press-and-hold accents,
      Finder path bar/extensions/hidden files, Dock autohide, screenshot location +
      format, trackpad tap-to-click. Every `defaults write` gets a comment saying what it
      does. Idempotent. [dep: M13]

---

## E3 — Terminal & multiplexer

- [ ] **M17 — Ghostty config at `bashrc/.config/ghostty/config`**
      Iosevka Term Nerd Font Mono, theme matching the nvim `noctishc` colours, sensible
      scrollback, `macos-option-as-alt` set (needed for zellij/nvim alt-bindings). Linked
      on darwin only. [dep: M03]

- [ ] **M18 — Zellij macOS adjustments**
      Uncomment `copy_command "pbcopy"` for darwin. Decide auto-start behaviour under
      Ghostty. Verify the `clear-defaults=true` keybind set doesn't collide with macOS
      system shortcuts (Cmd-based, so likely clean — confirm and document). [dep: M09]

---

## E4 — Window management & input

- [ ] **M19 — AeroSpace config mirroring the Hyprland keybinds** `needs-mac`
      **Port the existing binds so muscle memory transfers**: `hyprland.lua` uses
      SUPER+Q/C/M/E/V/R/P/L/S/J/Space, arrows for focus, SHIFT+arrows to move, 1–0 for
      workspaces. Map SUPER→Cmd or Alt and **document the choice and its tradeoff** — Cmd
      is closest to the existing finger positions but collides with macOS app shortcuts.
      Include the multi-monitor layout intent from the dual-monitor Hyprland setup.
      [dep: M03]

- [ ] **M20 — Raycast setup + config export path** `needs-mac`
      Document which Raycast features replace what (launcher ← rofi, clipboard history,
      window snapping, script commands ← hypr scripts). Establish where exported Raycast
      config lives in the repo. [dep: M15]

- [ ] **M21 — Karabiner-Elements config** `needs-mac`
      Mouse side-buttons → F13/F14, matching `windows/wezterm-mouse-buttons.ahk` and the
      existing nvim jumplist maps (`<F13>`/`<F14>` → back/forward, commit `bb0ab3b`).
      Optional Caps→Ctrl/Esc. [dep: M15]

---

## E5 — Toolchains: mise migration

- [ ] **M22 — `tools/mise.sh` + remove pyenv/nvm init blocks**
      Single `mise activate` line per shell. Delete the `PYENV_ROOT`/`pyenv init -` and
      `NVM_DIR` blocks from `.bashrc`. rustup and `~/.cargo/env` stay as-is. [dep: M06,
      M08]

- [ ] **M23 — `mise.toml` with pinned global tool versions**
      Python and Node pinned to match current usage (Python 3.11/3.13, Node LTS). Add
      `mise` to the Brewfile. Document the `mise use -g` workflow. [dep: M22]

- [ ] **M24 — Migrate the Linux distro scripts to mise**
      Update `linux/{ubuntu,debian,arch,opensuse}.sh` to install mise instead of
      pyenv+nvm, so machines don't diverge. Keep a documented escape hatch. **Needs Linux
      smoke-testing** — flag for the user, this touches working machines. [dep: M23]

---

## E6 — Embedded toolchain on macOS

- [ ] **M25 — `macos/embedded.sh` — ARM toolchain via xpm**
      Port `compilers/arm_gcc.sh` to darwin: keep the xpm + fzf version-picker flow (xPack
      ships native macOS arm64 builds and pins exact versions, e.g.
      `@xpack-dev-tools/arm-none-eabi-gcc@11.3.1-1.1.2` to match the current 11.3).
      Replace Linux `update-alternatives` with `~/.local/bin` shims. Document
      `brew install --cask gcc-arm-embedded` as fallback **and note its known flakiness**
      (ARM's server blocks Homebrew's user agent; SHA mismatches; case-sensitive-FS
      failures). [dep: M13]

- [ ] **M26 — Debug probe tooling** `needs-mac`
      `open-ocd` + `probe-rs` in the Brewfile. **Explicitly verify non-root ST-Link access
      on Apple Silicon** — a known pain point that may need a documented workaround.
      STM32CubeProgrammer is a manual ST download (native Apple Silicon build exists, Java
      installer, login required) → RUNBOOK entry. [dep: M25]

- [ ] **M27 — Make `clangd/config.yaml` toolchain path OS-aware**
      Currently hardcodes `/usr/local/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-eabi/…` —
      an x86_64 Linux path with no Darwin equivalent. Either generate it at bootstrap or
      template it per-OS. `--query-driver=**` behaviour must be preserved. [dep: M25]

- [ ] **M28 — Delete the WSL USB bridge layer on Mac**
      The `~/.local/bin` openocd interceptor and `plink.exe` ST-Link bridge exist purely
      because WSL cannot see USB. On macOS the ST-Link is a native USB device. Ensure none
      of that Windows-only machinery leaks into the Mac path; document the simplification.
      [dep: M10, M26]

---

## E7 — Git identity, SSH, secrets

- [ ] **M29 — Tracked `.gitconfig` with work/personal split**
      **There is currently no tracked gitconfig at all** — `user.name`/`user.email` are set
      as a side effect of `ssh/setup_ssh_key.sh create`. Add a tracked base config plus
      `includeIf gitdir:` sections so work repos get the work identity automatically and
      personal repos don't. Preserve `core.autocrlf input` and the `.githooks` path.
      [dep: M03]

- [ ] **M30 — `~/.ssh/config` template + macOS agent integration**
      Generalise `ssh/setup_AS_git.sh` (which appends the AutoStore host block). Add
      `UseKeychain yes` + `AddKeysToAgent yes` for macOS. Use the M09 `clip` abstraction
      instead of raw `xclip`. [dep: M09, M29]

- [ ] **M31 — Secrets story for the Mac**
      Keep the existing `~/.local/secrets/` + `symlink.py` `secret_links` scheme — it works
      fine on macOS. Document the work GitLab npm token (`GITLAB_ACCESS_KEY`) setup path.
      Confirm the root `.gitignore` allowlist still holds after the new `.config` entries
      from M17/M19. [dep: M03]

---

## E8 — Editors

- [ ] **M32 — nvim macOS fixes**
      `nvim/lua/plugins/floating-term.lua` hardcodes `vim.o.shell = "/bin/bash"` on
      non-Windows — **macOS `/bin/bash` is 3.2**, which breaks the `declare -gA` in
      `core/fn_wrapper.sh`. Point at the chosen shell instead. Verify clipboard integration
      and that the `<F13>`/`<F14>` jumplist maps work with M21. [dep: M21]

- [ ] **M33 — Wire Zed settings into the link map**
      `zed/settings.json` is **orphaned** — `symlink.py` never links it and
      `bashrc/.gitignore` ignores `.config/zed/`. It has been tracked since commit
      `acc5bdc` and never deployed anywhere. Resolve the contradiction and link it to
      `~/.config/zed/settings.json`. [dep: M03]

---

## E9 — Documentation & closing the loop

- [ ] **M34 — `macos/RUNBOOK.md`**
      The ordered day-one manual sequence: sign in, Xcode CLT, clone, bootstrap, grant
      Accessibility/Input-Monitoring permissions (AeroSpace, Karabiner and Raycast all need
      these — they cannot be scripted), ST download for CubeProgrammer, work VPN/SSO. Every
      `needs-mac` item accumulates a checklist entry here. [dep: M05]

- [ ] **M35 — README rewrite**
      Current README opens with stale Chocolatey notes. Restructure: per-OS setup, the
      shell architecture, the secrets scheme, the two verification tools. Also fix two
      stale docs found during survey: `nvim/README.md` still says "LazyVim starter
      template" (the config no longer uses the LazyVim distro), and `linux/README.md`
      describes a telescope-fzf-native fix for a plugin no longer installed. [dep: M34]

- [ ] **M36 — Post-arrival reconciliation**
      After the user runs the RUNBOOK and `doctor.sh --json` on real hardware, fold the
      findings back into the scripts and close out every `needs-mac` item. This is the
      epic that turns "should work" into "does work". [dep: all]

---

## Runner protocol

Each hourly agent run does **exactly one item**:

1. Read this file. Select the **first unchecked item whose dependencies are all ticked**
   and which is not blocked on `needs-mac` validation.
2. Comment on its GitHub issue to claim it.
3. Implement on branch `claude/mac-work-setup-gchgxr`.
4. Run `scripts/check.sh` — **must pass**. If the item introduces anything a machine could
   get wrong, add the matching check to `scripts/doctor.d/`. If the item is `needs-mac`,
   append the verification steps to `macos/RUNBOOK.md`.
5. Commit. `.githooks/commit-msg` enforces conventional commits with a **2–10 word, 10–50
   character summary and ≤72 char header** — comply or the commit is rejected.
6. Push and open a PR into `master`. Merge it yourself once checks pass — **except**
   `needs-mac` items and **M24**, which stay open and unmerged until the user validates
   them on hardware.
7. Tick the checkbox here, update the progress count, close the issue with a short summary
   of what changed, whether the PR merged, and anything the next agent should know.
8. **Stop.** One item per run, no batching.

If an item turns out to be mis-scoped or blocked, do not improvise: comment on the issue
explaining why, leave the box unchecked, and stop.

---

## Verification

**Per-item, in container:** `scripts/check.sh` — shellcheck, `bash -n`, `zsh -n`,
`stylua --check`, `lua pretty.lua -l`, and the `tests/test_symlink.py` fake-`$HOME` suite
asserting the exact link set under both darwin and linux.

**No-regression on Linux:** M06 and M22 are the risky ones. Before/after comparison of the
full alias + function inventory (`maliases` output, `compgen -A function`) must be
identical on Linux. Run `bootstrap.sh` against a fake `$HOME` and diff the link tree.

**On the actual Mac:**

1. **Pre-flight** — `./scripts/doctor.sh` on the untouched machine. Everything fails; that
   is the expected baseline and it confirms the tool runs on a bare system.
2. `git clone` → `./bootstrap.sh`.
3. **Post-flight** — `./scripts/doctor.sh` again. This is the real acceptance gate.
4. Manual spot-checks a script cannot make: Ghostty renders correctly, the AeroSpace
   keybinds feel right in the hand, Raycast responds.
5. `./scripts/doctor.sh --json` goes back to the agents to drive M36.

---

## Deliberately deferred

- **Raycast config versioning** — the export format is opaque; M20 establishes the path but
  versioning it properly may not be worth it.
- **nix-darwin** — more reproducible than a Brewfile, but a large rewrite that would fork
  the Linux setup. Brewfile is the right call for machine #1.
- **sketchybar** (macOS waybar equivalent) — deferred until you know whether you miss the
  Hyprland status bar. AeroSpace + the native menu bar may be enough.
