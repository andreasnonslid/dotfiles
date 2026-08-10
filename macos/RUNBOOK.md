# macOS day-one runbook

The ordered, checkable sequence for turning a brand-new work MacBook into a working
dev machine with this repo. Everything here either can't be scripted (GUI permission
grants, vendor logins, corporate SSO) or is the point where a script hands back
control to a human to confirm it actually worked.

Tick boxes as you go. If a step fails, don't skip ahead — later steps generally
assume earlier ones landed.

## 0. Before you start

- [ ] Signed in to macOS with the work Apple ID / local account
- [ ] Connected to the internet (Homebrew, `git clone`, and the CLT installer all need it)

## 1. Xcode Command Line Tools

`./bootstrap.sh` triggers this automatically (`macos/install.sh` calls
`xcode-select --install`), but it pops a GUI installer and blocks until you click
through it, so it's worth doing first and by hand if you'd rather not wait mid-clone:

- [ ] `xcode-select --install`, click through the GUI installer
- [ ] Confirm with `xcode-select -p` (prints a path, no error)

## 2. Clone this repo

- [ ] `git clone git@github.com:andreasnonslid/dotfiles.git ~/dotfiles`
    - No SSH key on this machine yet? Clone over HTTPS first
      (`git clone https://github.com/andreasnonslid/dotfiles.git ~/dotfiles`) and set up
      SSH afterwards per `ssh/README.md` — `bootstrap.sh` doesn't require SSH itself.
- [ ] `cd ~/dotfiles`

## 3. Pre-flight: `./scripts/doctor.sh`

Run it now, before touching anything else:

- [ ] `./scripts/doctor.sh`

**Expect almost everything to fail.** That's the correct baseline on an untouched
machine — Homebrew isn't installed, nothing is symlinked, no toolchains exist yet.
This run exists to prove `doctor.sh` itself works on a bare system, not to pass. If a
section errors out instead of reporting FAIL (a crash, not a diagnosis), that's a bug —
note it, it isn't expected.

## 4. Bootstrap

- [ ] `./bootstrap.sh`

This runs `configure_git.sh`, then `macos/install.sh` (Xcode CLT check, Homebrew
install, `brew bundle` against `macos/Brewfile` + `macos/Brewfile.casks`, the zellij
`copy_command` flip, `macos/defaults.sh`), then symlinks everything via `symlink.py`.
It's idempotent — safe to re-run if a step fails partway (e.g. Homebrew install times
out) rather than trying to hand-fix the partial state.

- [ ] Re-run `./bootstrap.sh` if anything above failed, once the underlying problem is
      fixed (network, a `brew` formula conflict, etc.)

## 5. Permission grants (cannot be scripted)

Three casks from `macos/Brewfile.casks` need explicit grants in **System Settings →
Privacy & Security** before they work. macOS does not prompt reliably for all of
these on first launch, and a missing grant fails **silently** — the app opens, looks
fine, and just doesn't respond to keybinds or synthesize input. If AeroSpace isn't
switching workspaces, or Karabiner isn't remapping, or Raycast's hotkey does nothing,
this section is almost always why.

| App                | Pane                                      | Why                                                       |
| ------------------ | ----------------------------------------- | --------------------------------------------------------- |
| AeroSpace          | Privacy & Security → **Accessibility**    | Moves/resizes windows and switches focus (M19)            |
| Karabiner-Elements | Privacy & Security → **Input Monitoring** | Reads raw key/mouse events to remap them (M21)            |
| Karabiner-Elements | Privacy & Security → **Accessibility**    | Also required for its virtual HID driver to inject events |
| Raycast            | Privacy & Security → **Accessibility**    | Window management + input-emulating extensions (M20)      |

- [ ] Open **System Settings → Privacy & Security → Accessibility**, enable AeroSpace,
      Karabiner-Elements, Raycast
- [ ] Open **System Settings → Privacy & Security → Input Monitoring**, enable
      Karabiner-Elements
- [ ] Launch each app once after granting — some only pick up the grant on next launch,
      not live
- [ ] Karabiner-Elements also installs a system extension on first run; approve it in
      **System Settings → General → Login Items & Extensions → Driver Extensions** if
      macOS prompts for it separately from the two panes above

## 6. Embedded toolchain (optional, only if you need it)

Not run by `bootstrap.sh` — opt in when you actually need to build firmware:

- [ ] `./macos/embedded.sh` — picks an xPack `arm-none-eabi-gcc` version via `fzf`,
      shims it into `~/.local/bin`, regenerates `~/.config/clangd/config.yaml`
    - Fallback if xpm is unavailable: `brew install --cask gcc-arm-embedded` — known to
      be flaky (ARM's download server periodically blocks Homebrew's user agent, SHA256
      mismatches, and failures on case-sensitive APFS volumes), so prefer the xpm path
- [ ] **STM32CubeProgrammer**: not packaged anywhere scriptable. Manual download from
      [st.com](https://www.st.com/en/development-tools/stm32cubeprog.html), which
      requires creating/logging into a free ST account, then run the `.pkg` installer
      it ships (Java-based GUI installer)
- [ ] Debug probe: plug in the ST-Link and confirm it's visible **without `sudo`** —
      `probe-rs list` should list it. Apple Silicon + non-root USB access to ST-Link
      is a known pain point; if the probe doesn't show up, check
      **System Settings → Privacy & Security** for a USB-related prompt first before
      assuming a driver problem (M26 tracks a documented workaround once one exists)

## 7. Work setup (VPN / SSO / corporate tooling)

Placeholder — fill in with AutoStore's actual onboarding steps as they're confirmed on
real hardware. Known pieces so far:

- [ ] Work VPN client: _not yet documented — add install/config steps here_
- [ ] Corporate SSO (Okta/similar, if applicable): _not yet documented_
- [ ] Work git identity: covered by the tracked `.gitconfig`'s `includeIf` split — clone
      work repos under `~/work/` and the work identity
      (`~/.local/secrets/git/work.gitconfig`) applies automatically. See the "Git
      identity" section of the root `README.md`.
- [ ] Work GitLab npm token (`GITLAB_ACCESS_KEY`): see the "Secrets" section of the root
      `README.md` — drop it in `~/.local/secrets/autostore/gitlab-npm.env` and re-run
      `./bootstrap.sh`
- [ ] SSH host block for the work git host: `./ssh/setup_git_host.sh <host> <key-domain>`
      (see `ssh/README.md`) — e.g.
      `./ssh/setup_git_host.sh as-git.autostoresystem.com autostoresystem.com`

## 8. Post-flight: `./scripts/doctor.sh`

- [ ] `./scripts/doctor.sh`

This is the real acceptance gate — after bootstrap, permissions, and work setup, this
should mostly be `PASS`, with `WARN` only for genuinely optional things (embedded
toolchain, if you skipped step 6). Any `FAIL` here is a real problem to chase down
before calling the machine done.

- [ ] Run with `--verbose` to see hints for every check, not just non-passing ones:
      `./scripts/doctor.sh --verbose`
- [ ] Spot-check a single section while iterating, e.g.
      `./scripts/doctor.sh --only homebrew`

## 9. Manual spot-checks (nothing scripts these)

- [ ] Ghostty renders correctly — font (Iosevka Term Nerd Font Mono), theme, no
      tofu/missing glyphs
- [ ] AeroSpace keybinds feel right in the hand — SUPER (Cmd or Alt, per the tradeoff
      documented alongside the AeroSpace config once M19 lands) +
      Q/C/M/E/V/R/P/L/S/J/Space, arrows for focus, SHIFT+arrows to move, 1–0 for
      workspaces
- [ ] Raycast's hotkey responds and clipboard history works
- [ ] Karabiner remaps take effect (mouse side-buttons, Caps→Ctrl/Esc if configured)

## 10. Hand results back to the agents

- [ ] `./scripts/doctor.sh --json > /tmp/doctor.json` and share the output — this drives
      M36, the final reconciliation that folds real-hardware findings back into the
      scripts and closes out every `needs-mac` item

---

## Backlog cross-reference

Every `needs-mac` item in `docs/mac-setup/BACKLOG.md` has a corresponding step above:

| Item                                   | Where it's covered                                                                                                       |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| D06 — macOS-specific doctor checks     | Step 8 (post-flight doctor run)                                                                                          |
| D07 — Embedded toolchain check         | Step 6 (probe + doctor run)                                                                                              |
| M16 — `macos/defaults.sh` system prefs | Step 4 (bootstrap runs it); spot-check the panes it touches (key repeat, Finder, Dock, trackpad) against what you expect |
| M19 — AeroSpace config                 | Step 5 (permission grant), Step 9 (spot-check)                                                                           |
| M20 — Raycast setup                    | Step 5 (permission grant), Step 9 (spot-check)                                                                           |
| M21 — Karabiner-Elements config        | Step 5 (permission grant), Step 9 (spot-check)                                                                           |
| M26 — Debug probe tooling              | Step 6 (non-root ST-Link access)                                                                                         |
