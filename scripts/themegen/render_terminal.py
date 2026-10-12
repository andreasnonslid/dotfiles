"""Renderers for terminal-side parts: alacritty, starship, zellij, nvim, fzf/bat."""
from pathlib import Path
import re
from .core import COLOR_KEYS, GEN, ROOT, mix


def r_alacritty(c, s):
    a = c["ansi"]
    n = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    col = f"# {GEN}\n"
    col += f'[colors.primary]\nbackground = "{c["bg"]}"\nforeground = "{c["fg"]}"\n\n'
    col += f'[colors.cursor]\ncursor = "{c["accent"]}"\ntext = "{c["bg"]}"\n\n'
    col += f'[colors.selection]\nbackground = "{c["accent"]}"\ntext = "{c["bg"]}"\n\n'
    for sect in ("normal", "bright"):
        col += f"[colors.{sect}]\n" + "".join(f'{k} = "{v}"\n' for k, v in zip(n, a)) + "\n"
    pad = 0 if s["density"] == "compact" else max(s["gaps_inner"], 4)
    sty = (f"# {GEN}\n[window]\nopacity = {s['opacity']}\ndynamic_padding = true\n"
           f"padding = {{ x = {pad}, y = {pad} }}\n")
    d = "alacritty/.config/alacritty/"
    return {d + "colors.toml": col, d + "style.toml": sty}


def r_starship(c, s):
    two = s["density"] == "cozy"
    fmt = "$status$directory$git_branch$git_status$cmd_duration"
    fmt += "$time$line_break$character" if two else "$character"
    pal = "".join(f'{k} = "{c[k]}"\n' for k in COLOR_KEYS)
    t = f"""# {GEN}
palette = "dotfiles"
add_newline = {"true" if two else "false"}
format = "{fmt}"

[palettes.dotfiles]
{pal}red = "{c['urgent']}"
green = "{c['ansi'][2]}"
blue = "{c['accent2']}"
cyan = "{c['ansi'][6]}"
yellow = "{c['warn']}"

[directory]
style = "accent bold"
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "on [($branch)]($style) "
style = "accent2"

[git_status]
format = "([$all_status$ahead_behind]($style) )"
style = "warn"

[cmd_duration]
format = "took [($duration)]($style) "
style = "dim"

[status]
disabled = false
format = "[$symbol]($style)"
symbol = "✘ "
success_symbol = "✔ "
style = "bold urgent"
success_style = "bold green"
failure_style = "bold urgent"

[time]
disabled = {"false" if two else "true"}
format = "[$time]($style) "
style = "dim"
time_format = "%H:%M"

[character]
success_symbol = "[❯](accent)"
error_symbol = "[❯](urgent)"
"""
    return {str(ROOT / "starship.toml"): t}


def r_zellij(c, s):
    """Component theme (zellij 0.43+): dark surfaces, light text, accent emphasis."""
    a = c["ansi"]
    surf = mix(c["bg"], c["fg"], 0.10)   # status bar / unselected ribbons
    surf2 = mix(c["bg"], c["fg"], 0.18)  # selected text rows
    dk = mix(c["bg"], "#000000", 0.35)   # readable on an accent background

    def comp(name, base, bgc, e0, e1, e2, e3):
        return (f'        {name} {{\n            base "{base}"\n            background "{bgc}"\n'
                f'            emphasis_0 "{e0}"\n            emphasis_1 "{e1}"\n'
                f'            emphasis_2 "{e2}"\n            emphasis_3 "{e3}"\n        }}\n')

    em = (c["accent"], c["accent2"], a[2], c["warn"])
    body = "".join([
        comp("text_unselected", c["fg"], c["bg"], *em),
        comp("text_selected", c["fg"], surf2, *em),
        # emphasis_1 doubles as the background of every second (alternate) inactive tab,
        # so it must be a quiet surface, not an accent.
        comp("ribbon_unselected", c["fg"], surf, c["accent"], mix(c["bg"], c["fg"], 0.22), a[2], c["warn"]),
        comp("ribbon_selected", c["bg"], c["accent"], dk, dk, dk, dk),
        comp("table_title", c["accent"], c["bg"], *em),
        comp("table_cell_unselected", c["fg"], c["bg"], *em),
        comp("table_cell_selected", c["fg"], surf2, *em),
        comp("list_unselected", c["fg"], c["bg"], *em),
        comp("list_selected", c["fg"], surf2, *em),
        comp("frame_unselected", c["dim"], c["bg"], *em),
        comp("frame_selected", c["accent"], c["bg"], *em),
        comp("frame_highlight", c["warn"], c["bg"], *em),
        comp("exit_code_success", a[2], c["bg"], *em),
        comp("exit_code_error", c["urgent"], c["bg"], *em),
    ])
    players = "".join(f'            player_{i + 1} "{col}"\n' for i, col in enumerate(
        [c["accent"], c["accent2"], a[2], c["warn"], c["urgent"], a[5], a[6], c["fg"], c["dim"], a[0]]))
    t = (f"// {GEN}\nthemes {{\n    dotfiles {{\n{body}"
         f"        multiplayer_user_colors {{\n{players}        }}\n    }}\n}}\n")
    out = {str(ROOT / "bashrc/.config/zellij/themes/dotfiles.kdl"): t}
    home = Path.home() / ".config/zellij"
    if home.is_dir() and not home.is_symlink():  # machine not bootstrapped: theme it in place
        out[str(home / "themes/dotfiles.kdl")] = t
    return out


def zellij_options(s):
    """Managed option lines inside the hand-written config.kdl."""
    home = Path.home() / ".config/zellij/config.kdl"
    for p in [ROOT / "bashrc/.config/zellij/config.kdl"] + ([home] if home.is_file() and not home.is_symlink() else []):
        if p.exists():
            zellij_edit(p, s)


def zellij_edit(p, s):
    bak = p.with_name(p.name + ".pre-theme")
    if p != ROOT / "bashrc/.config/zellij/config.kdl" and not bak.exists():
        bak.write_text(p.read_text())
    txt = p.read_text()
    cozy = s["density"] == "cozy"
    for key, val, anchor in [
        ("theme", '"dotfiles"', '// theme "dracula"'),
        ("pane_frames", "true" if cozy else "false", None),
        ("simplified_ui", "false" if cozy else "true", "// simplified_ui true"),
    ]:
        line = f"{key} {val}"
        if re.search(rf"^{key} ", txt, re.M):
            txt = re.sub(rf"^{key} .*$", line, txt, flags=re.M)
        elif anchor and anchor in txt:
            txt = txt.replace(anchor, anchor + "\n" + line, 1)
        else:
            txt += "\n" + line + "\n"
    p.write_text(txt)


def r_nvim(c, s):
    pal = "".join(f'  {k} = "{c[k]}",\n' for k in COLOR_KEYS)
    a = c["ansi"]
    lua = f"""-- {GEN}
local p = {{
{pal}  red = "{c['urgent']}", green = "{a[2]}", yellow = "{c['warn']}",
  blue = "{c['accent2']}", magenta = "{c['accent']}", cyan = "{a[6]}", black = "{a[0]}",
}}
vim.cmd("highlight clear")
vim.g.colors_name = "palette"
vim.o.termguicolors = true
local function hl(g, o) vim.api.nvim_set_hl(0, g, o) end
local groups = {{
  Normal = {{ fg = p.fg, bg = p.bg }}, NormalFloat = {{ fg = p.fg, bg = p.bg }},
  FloatBorder = {{ fg = p.accent, bg = p.bg }}, CursorLine = {{ bg = p.black }},
  CursorLineNr = {{ fg = p.accent, bold = true }}, LineNr = {{ fg = p.dim }},
  Visual = {{ bg = p.black }}, Search = {{ fg = p.bg, bg = p.warn }},
  IncSearch = {{ fg = p.bg, bg = p.accent }}, Pmenu = {{ fg = p.fg, bg = p.black }},
  PmenuSel = {{ fg = p.bg, bg = p.accent }}, StatusLine = {{ fg = p.fg, bg = p.black }},
  StatusLineNC = {{ fg = p.dim, bg = p.bg }}, VertSplit = {{ fg = p.dim }},
  WinSeparator = {{ fg = p.dim }}, SignColumn = {{ bg = p.bg }}, Folded = {{ fg = p.dim, bg = p.black }},
  Comment = {{ fg = p.dim, italic = true }}, String = {{ fg = p.green }},
  Constant = {{ fg = p.yellow }}, Number = {{ fg = p.yellow }}, Boolean = {{ fg = p.yellow }},
  Identifier = {{ fg = p.fg }}, Function = {{ fg = p.blue }}, Statement = {{ fg = p.magenta }},
  Keyword = {{ fg = p.magenta }}, Operator = {{ fg = p.cyan }}, Type = {{ fg = p.yellow }},
  PreProc = {{ fg = p.accent2 }}, Special = {{ fg = p.cyan }}, Title = {{ fg = p.accent, bold = true }},
  MatchParen = {{ fg = p.accent, bold = true, underline = true }},
  Error = {{ fg = p.red }}, ErrorMsg = {{ fg = p.red }}, WarningMsg = {{ fg = p.yellow }},
  DiagnosticError = {{ fg = p.red }}, DiagnosticWarn = {{ fg = p.yellow }},
  DiagnosticInfo = {{ fg = p.blue }}, DiagnosticHint = {{ fg = p.cyan }},
  DiffAdd = {{ fg = p.green }}, DiffChange = {{ fg = p.yellow }}, DiffDelete = {{ fg = p.red }},
  Added = {{ fg = p.green }}, Changed = {{ fg = p.yellow }}, Removed = {{ fg = p.red }},
  Directory = {{ fg = p.blue }}, NonText = {{ fg = p.dim }}, SpecialKey = {{ fg = p.dim }},
}}
for g, o in pairs(groups) do hl(g, o) end
"""
    return {str(ROOT / "nvim/colors/palette.lua"): lua}


def r_env(c, s):
    b = "rounded" if s["density"] == "cozy" else "sharp"
    fzf = (f"--color=bg:{c['bg']},bg+:{c['ansi'][0]},fg:{c['fg']},fg+:{c['fg']},"
           f"hl:{c['accent']},hl+:{c['accent']},info:{c['dim']},prompt:{c['accent2']},"
           f"pointer:{c['accent']},marker:{c['warn']},spinner:{c['accent']},header:{c['dim']},"
           f"border:{c['dim']} --border={b} --info=inline")
    t = f"""# {GEN}
export FZF_DEFAULT_OPTS="{fzf}"
export BAT_THEME=ansi
"""
    return {"palette/.config/palette/env.sh": t}
