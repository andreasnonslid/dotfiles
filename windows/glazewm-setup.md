# GlazeWM tiling window manager

Alt-based tiling for Windows, keybinds mirroring the Hyprland setup
(`bashrc/.config/hypr/hyprland.lua`) and the still-to-land AeroSpace config
for macOS (M19 in the mac-setup backlog) — same modifier, same keys, so the
muscle memory carries across all three machines. See the header comment in
`glazewm-config.yaml` for the full Hyprland-to-GlazeWM binding map and what
deliberately isn't carried over.

## Install

```powershell
winget install glzr-io.glazewm
```

## Deploy the config

GlazeWM reads `%userprofile%\.glzr\glazewm\config.yaml`. Symlink it to the
tracked copy in this repo (elevated/Developer Mode PowerShell required for
`New-Item -ItemType SymbolicLink`):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.glzr\glazewm" | Out-Null
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.glzr\glazewm\config.yaml" -Target "<path-to-this-repo>\windows\glazewm-config.yaml"
```

Or just copy the file if you'd rather not symlink — re-copy after editing
either side.

## Applying changes

GlazeWM does not watch `config.yaml` for changes. After editing it, press
`alt+shift+r` (bound to `wm-reload-config`) or restart the app — neither
happens automatically on save.

## Not yet verified

Written against GlazeWM's documented config schema, never run for real —
there's no Windows machine available to test this from here. Once you've
tried it, worth confirming:

- The `shell-exec wezterm`/`shell-exec explorer` binds actually launch what's
  expected (`wezterm` needs to resolve on `PATH`).
- `alt+r` resize mode doesn't collide with anything you use often.
- Whether `Alt` conflicts with any of your regularly-used apps' own menu
  mnemonics (Windows' classic `Alt` opens the menu bar in older apps) enough
  to be annoying in practice.
