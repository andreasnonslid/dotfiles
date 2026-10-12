"""The leader menu (single source) and what is derived from it: the which-key YAML and the Hyper+key bindings."""
from .core import GEN, ME, names


# Nerd Font (Font Awesome range) glyphs for the leader menu.
I = {
    "left": "", "down": "", "up": "", "right": "",
    "ws": "", "move": "", "full": "", "close": "",
    "layout": "", "resize": "", "apps": "", "term": "",
    "search": "", "kbd": "", "lock": "", "out": "",
    "sleep": "", "reboot": "", "off": "", "theme": "",
    "color": "", "shape": "", "clip": "", "bell": "", "drop": "",
}


SWAY = "swaymsg "


def pick_menu(kind, verb):
    """One submenu entry per name, key = first letter not yet used."""
    used, kids = set(), []
    for n in names(kind):
        key = next(ch for ch in n if ch.isalpha() and ch not in used)
        used.add(key)
        kids.append((key, n, f"{ME} {verb} {n}"))
    return kids


def menu(c):
    """(key, desc, cmd | [children]) -- single source for the which-key popup."""
    m = []
    for k, d in [("h", "left"), ("j", "down"), ("k", "up"), ("l", "right")]:
        m.append((k, f"{I[d]}  Focus {d}", SWAY + f"focus {d}"))
    for k, d in [("H", "left"), ("J", "down"), ("K", "up"), ("L", "right")]:
        m.append((k, f"{I['move']}  Move {d}", SWAY + f"move {d}"))
    for n in range(1, 10):
        m.append((str(n), f"{I['ws']}  Workspace {n}", SWAY + f"workspace number {n}"))
    return m + [
        ("f", f"{I['full']}  Fullscreen", SWAY + "fullscreen toggle"),
        ("x", f"{I['close']}  Close window", SWAY + "kill"),
        ("r", f"{I['resize']}  Resize mode", SWAY + "mode resize"),
        ("o", f"{I['kbd']}  On-screen keyboard", "~/.config/sway/osk-toggle.sh"),
        ("c", f"{I['clip']}  Clipboard history", "~/.config/sway/clipboard.sh"),
        ("n", f"{I['bell']}  Restore notification", "makoctl restore"),
        ("d", f"{I['drop']}  Drop-down terminal", "~/.config/sway/scratch.sh"),
        ("m", f"{I['move']}  Move to workspace",
         [(str(n), f"To {n}", SWAY + f"move container to workspace number {n}") for n in range(1, 10)]),
        ("t", f"{I['layout']}  Layout", [
            ("s", "Stacking", SWAY + "layout stacking"),
            ("w", "Tabbed", SWAY + "layout tabbed"),
            ("e", "Split toggle", SWAY + "layout toggle split"),
            ("v", "Split vertical", SWAY + "splitv"),
            ("b", "Split horizontal", SWAY + "splith"),
        ]),
        ("a", f"{I['apps']}  Apps", [
            ("t", f"{I['term']}  Terminal", "alacritty"),
            ("d", f"{I['search']}  Launcher", "fuzzel"),
        ]),
        ("z", f"{I['theme']}  Theme", [
            ("c", f"{I['color']}  Colors", pick_menu("colors", "colors")),
            ("s", f"{I['shape']}  Style", pick_menu("styles", "style")),
            ("n", "Next colors", f"{ME} next-colors"),
            ("r", "Random", f"{ME} random"),
        ]),
        ("q", f"{I['off']}  Session", [
            ("l", f"{I['lock']}  Lock", "~/.config/sway/lock.sh"),
            ("e", f"{I['out']}  Log out", SWAY + "exit"),
            ("s", f"{I['sleep']}  Suspend", "systemctl suspend"),
            ("r", f"{I['reboot']}  Reboot", "systemctl reboot"),
            ("p", f"{I['off']}  Power off", "systemctl poweroff"),
            ("u", f"{I['reboot']}  Firmware setup (UEFI)", "systemctl reboot --firmware-setup"),
        ]),
    ]


def hyper_bindings(c):
    """Direct keys, generated from menu() so they can never drift from the leader menu.

    Rule: Hyper+X is exactly Hyper+Space, X. A leaf runs directly; a group opens the same popup
    already inside that group (so a whole group, e.g. everything under q, is reached one way).
    Shift is part of Hyper, so only lowercase letters and digits can be direct; the uppercase
    move keys (H J K L) stay inside the menu.
    """
    wk = "~/.cargo/bin/wlr-which-key"
    out = [f"# {GEN}", "# Hyper+X == Hyper+Space then X (lowercase). Edit menu() in scripts/theme.py."]
    for key, _desc, cmd in menu(c):
        if not (key.islower() or key.isdigit()):
            continue
        if isinstance(cmd, list):
            out.append(f"bindsym $hyper+{key} exec {wk} --initial-keys {key}")
        elif cmd.startswith(SWAY):
            out.append(f"bindsym $hyper+{key} {cmd[len(SWAY):]}")
        else:
            out.append(f"bindsym $hyper+{key} exec {cmd}")
    return "\n".join(out) + "\n"


def yaml_menu(items, ind):
    out = []
    for k, d, cmd in items:
        pad = "  " * ind
        out += [f'{pad}- key: "{k}"', f'{pad}  desc: "{d}"']
        if isinstance(cmd, list):
            out.append(f"{pad}  submenu:")
            out += yaml_menu(cmd, ind + 2)
        else:
            out.append(f'{pad}  cmd: "{cmd}"')
    return out
