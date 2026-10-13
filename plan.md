# Hyper binding generator

One person, one mechanism. Linux and macOS should share the same Hyper definition and the same keys. Implement this later. Do not change the live Sway Hyper line until the generator exists and its output has been checked.

## Current split

Hyper is Caps Lock held, used as the tiling leader.

- macOS, AeroSpace: `ctrl+alt+cmd`. Shift is not part of Hyper. `Hyper+h/j/k/l` focuses, `Hyper+Shift+h/j/k/l` moves. Defined by hand in `parts/aerospace/.config/aerospace/aerospace.toml`. Hammerspoon hint text in `parts/hammerspoon/.hammerspoon/init.lua` is a second copy of those labels.
- Linux, Sway: `set $hyper Ctrl+Mod1+Mod4+Shift` in `parts/sway/.config/sway/config`. Shift is inside Hyper, so there is no separate move chord. Binds live in `parts/sway/.config/sway/hyper.conf`.

Sway gaps are already `outer 0` / `inner 4` (`parts/sway/.config/sway/style.conf`). AeroSpace outer and inner gaps are `0`.

## What to build

A single binding table is the only place that defines Hyper and the keys. A script reads it and writes the per-OS files. Same pattern as `scripts/theme.py`: run by hand, commit the generated files, do not generate them at login.

Hyper in the table:

- Linux: `Ctrl+Mod1+Mod4` (Ctrl+Alt+Super)
- macOS: `ctrl+alt+cmd`

Shift is never part of Hyper. Shift is a column on a row (`focus` vs `move`).

Each row: key, whether Shift is held, a shared action name (`focus left`, `move left`, `workspace 3`), and optional per-OS commands (Sway `makoctl`, macOS `pmset`, Ghostty, Raycast). Mark Linux-only and macOS-only rows and skip them on the other side.

The script writes only the binding sections, not the rest of the configs:

- Sway: `set $hyper Ctrl+Mod1+Mod4` and `parts/sway/.config/sway/hyper.conf`, including `$hyper+Shift+…` for move.
- AeroSpace: `mode.main.binding` chords, `ctrl-alt-cmd-…` and `ctrl-alt-cmd-shift-…`.
- Leader card and Hammerspoon hint pages, from the same labels, so the card cannot drift from the keys.

Leader mode (Hyper+Space, then a bare key) uses the same rows: the direct chord and the leader key are two renderings of one row.

## Out of scope

Do not generate all of `sway/config` or `aerospace.toml`. Leave startup, colors, gaps, and layouts hand-written.

Do not flip the live Sway `$hyper` line as a one-off edit. That would desync `hyper.conf`, which has no Shift-for-move binds yet. Land both together as generator output.
