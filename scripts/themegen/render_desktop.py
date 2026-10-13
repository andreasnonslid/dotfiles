"""Renderers for desktop parts: sway, waybar, launcher, popup, notifications, lock screens, GTK."""

from pathlib import Path
from .core import COLOR_KEYS, FONT, GEN
from .menu import hyper_bindings, menu, yaml_menu


def r_sway(c, s):
    col = f"# {GEN}\n" + "".join(f"set ${k} {c[k]}\n" for k in COLOR_KEYS)
    col += f"set $bgrgb {c['bg'].lstrip('#')}\n"
    col += "# The lock frame (art + quote): the first thing sway shows, and the lock screen's background.\n# bg-state.sh / lock.sh put the real wallpaper back once the session is unlocked.\n"
    col += "output * bg ~/.local/share/palette/lock-frame.png fill\n"
    sty = f"""# {GEN}
default_border pixel {s['border']}
gaps inner {s['gaps_inner']}
gaps outer {s['gaps_outer']}
smart_borders on
smart_gaps on
seat * xcursor_theme dotfiles 24
"""
    return {
        "sway/.config/sway/colors.conf": col,
        "sway/.config/sway/style.conf": sty,
        "sway/.config/sway/hyper.conf": hyper_bindings(c),
    }


def r_waybar(c, s):
    col = f"/* {GEN} */\n" + "".join(f"@define-color {k} {c[k]};\n" for k in COLOR_KEYS)
    m = s["bar_margin"]
    # window icons shown inside each workspace button (app_id regex -> icon)
    icons = (
        {  # ECMAScript regex (waybar uses std::regex): no (?i), so spell out the cases
            "[Aa]lacritty|foot|kitty": "\uf120",
            "[Ff]irefox.*": "\uf269",
            "[Cc]hrom.*|[Bb]rave.*|[Gg]oogle-chrome.*": "\uf268",
            "[Cc]ode.*|[Cc]ursor.*|[Zz]ed.*": "\uf121",
            "[Oo]bsidian": "\U000f0b6e",
            "org.gnome.[Nn]autilus|[Tt]hunar": "\uf07b",
            "[Ss]lack": "\uf198",
            "[Dd]iscord": "\uf392",
            "[Ss]potify": "\uf1bc",
            "[Pp]avucontrol": "\uf028",
            "[Ll]ibreoffice.*": "\uf1c2",
            "mpv|vlc": "\uf03d",
        }
    )
    rewrite = ",\n".join(f'        "class<{k}>": "{v}"' for k, v in icons.items())
    cfg = f"""// {GEN}
{{
    "layer": "top",
    "position": "top",
    "height": {s['bar_height']},
    "margin-top": {m},
    "margin-left": {m},
    "margin-right": {m},
    "spacing": 8,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": [],
    "modules-right": ["mpris", "tray", "group/status", "clock", "custom/ready"],

    "group/status": {{
        "orientation": "horizontal",
        "modules": ["bluetooth", "network", "pulseaudio", "backlight", "battery", "cpu", "memory"]
    }},

    "sway/workspaces": {{
        "disable-scroll": false,
        "all-outputs": false,
        "format": "{{index}} {{windows}}",
        "window-format": "{{icon}}",
        "window-rewrite-default": "\uf2d0",
        "window-rewrite": {{
{rewrite}
        }}
    }},

    "mpris": {{
        "format": "{{status_icon}}  {{title}}",
        "status-icons": {{ "playing": "\uf04b", "paused": "\uf04c" }},
        "max-length": 34,
        "on-click": "playerctl play-pause",
        "on-scroll-up": "playerctl next",
        "on-scroll-down": "playerctl previous",
        "tooltip-format": "{{player}}: {{artist}} \u2013 {{title}}"
    }},

    "bluetooth": {{
        "align": 0.5,
        "format": "\U000f00af {{num_connections}}",
        "format-connected": "\U000f00b1 {{num_connections}}",
        "format-off": "\U000f00b2",
        "format-disabled": "\U000f00b2",
        "tooltip-format": "Bluetooth on  \u00b7  {{num_connections}} connected",
        "tooltip-format-connected": "{{device_enumerate}}",
        "tooltip-format-enumerate-connected": "{{device_alias}}",
        "on-click": "~/.config/sway/bluetooth-menu.sh",
        "on-click-right": "blueman-manager"
    }},

    "network": {{
        "align": 0.5,
        "format-wifi": "{{icon}}",
        "format-icons": ["\U000f092f", "\U000f091f", "\U000f0922", "\U000f0925", "\U000f0928"],
        "format-ethernet": "\U000f0200",
        "format-disconnected": "\U000f092e",
        "tooltip-format-wifi": "{{essid}}  \u00b7  {{signalStrength}}%\\n{{ipaddr}}",
        "tooltip-format-disconnected": "Not connected",
        "on-click": "alacritty --class nmtui-float -e nmtui",
        "on-click-right": "nm-connection-editor"
    }},

    "pulseaudio": {{
        "align": 0.5,
        "format": "{{icon}} {{volume}}%",
        "format-muted": "\U000f075f",
        "format-icons": {{ "default": ["\U000f057f", "\U000f0580", "\U000f057e"] }},
        "scroll-step": 5,
        "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        "on-click-right": "pavucontrol"
    }},

    "backlight": {{
        "format": "\U000f00e0",
        "tooltip-format": "Brightness {{percent}}%",
        "on-scroll-up": "brightnessctl set 5%+",
        "on-scroll-down": "brightnessctl set 5%-"
    }},

    "battery": {{
        "align": 0.5,
        "states": {{ "warning": 25, "critical": 12 }},
        "format": "{{icon}} {{capacity}}%",
        "format-charging": "\U000f0084 {{capacity}}%",
        "format-icons": ["\U000f007a", "\U000f007c", "\U000f007f", "\U000f0081", "\U000f0079"],
        "tooltip-format": "{{timeTo}}"
    }},

    "cpu": {{
        "interval": 3,
        "states": {{ "warning": 85 }},
        "format": "",
        "format-warning": "\U000f0ee0 {{usage}}%"
    }},

    "memory": {{
        "interval": 5,
        "states": {{ "warning": 85 }},
        "format": "",
        "format-warning": "\U000f035b {{percentage}}%"
    }},

    "clock": {{
        "align": 0.5,
        "format": "\uf017  {{:%a %d %b   %H:%M}}",
        "format-alt": "\uf017  {{:%H:%M}}",
        "tooltip-format": "{{calendar}}"
    }},

    "tray": {{ "spacing": 8 }},

    "custom/ready": {{ "format": "", "exec": "touch $XDG_RUNTIME_DIR/waybar-ready", "interval": "once", "tooltip": false }}
}}
"""
    border = "" if s["bar_border"] == "none" else f"border-bottom: {s['bar_border']};"
    r, p = s["radius"], s["mod_pad"]
    w = lambda chars: round(
        chars * s["font_size"] * 0.58
    )  # Iosevka Term advance ~0.5em, plus margin
    mods = "#workspaces, #mode, #clock, #tray, #mpris, #status"
    css = f"""/* {GEN} */
@import "colors.css";

* {{ font-family: "{FONT}"; font-size: {s['font_size']}px; border: none; border-radius: 0; min-height: 0; }}
window#waybar {{ background: {s['bar_bg']}; color: @fg; {border} }}

{mods} {{
    background: {s['mod_bg']};
    border-radius: {r}px;
    padding: 2px {p}px;
    margin: 0;
}}

#workspaces {{ padding: 0 4px; }}
#workspaces button {{ color: @dim; padding: 0 10px; margin: 3px 2px; border-radius: {max(r - 4, 0)}px; background: transparent; }}
#workspaces button:hover {{ background: alpha(@accent, 0.25); color: @fg; }}
#workspaces button.focused {{ color: @bg; background: @accent; font-weight: bold; }}
#workspaces button.urgent {{ color: @bg; background: @urgent; }}

/* The status cluster is one pill; its members are flat and tight so no module drags air along. */
#network, #bluetooth, #pulseaudio, #backlight, #battery, #cpu, #memory {{
    background: transparent; padding: 0 6px; margin: 0;
}}
#pulseaudio, #battery {{ min-width: {w(5)}px; }}
#bluetooth {{ min-width: {w(2)}px; }}

/* The clock: its own pill at a fixed width, so it never moves. */
#clock {{ min-width: {w(18)}px; color: @accent2; font-weight: bold; }}

#mode {{ color: @bg; background: @warn; font-weight: bold; }}
#mpris {{ color: @accent; }}
#network {{ color: @accent; }}
#bluetooth {{ color: @accent2; }}
#bluetooth.off, #bluetooth.disabled {{ color: @dim; }}
#cpu.warning, #memory.warning {{ color: @warn; }}
#backlight {{ color: @warn; }}
#pulseaudio {{ color: @accent2; }}
#pulseaudio.muted {{ color: @dim; }}
#battery {{ color: @accent; }}
#battery.warning {{ color: @warn; }}
#battery.critical {{ color: @urgent; }}
"""
    d = "waybar/.config/waybar/"
    return {d + "colors.css": col, d + "config.jsonc": cfg, d + "style.css": css}


def r_fuzzel(c, s):
    h = lambda k, a="ff": c[k].lstrip("#") + a
    ini = f"""# {GEN}
[main]
font={FONT}:size={s['font_size'] + 1}
prompt="  "
icon-theme=Adwaita
width=42
lines={s['lines']}
horizontal-pad={s['pad'] + 8}
vertical-pad={s['pad']}
inner-pad=8
line-height={s['font_size'] + 12}

[colors]
background={h('bg', 'f2')}
text={h('fg')}
match={h('accent')}
selection={h('accent', '33')}
selection-text={h('fg')}
selection-match={h('accent2')}
border={h('accent')}
prompt={h('accent2')}
input={h('fg')}
placeholder={h('dim')}

[border]
width={s['border']}
radius={s['radius']}
"""
    return {"fuzzel/.config/fuzzel/fuzzel.ini": ini}


def r_whichkey(c, s):
    head = f"""# {GEN} Change menu() in scripts/theme.py.
font: {FONT} {s['font_size'] + 1}
background: "{c['bg']}f2"
color: "{c['fg']}"
border: "{c['accent']}"
separator: "  ➜  "
border_width: {s['wk_border']}
corner_r: {s['radius'] + 2}
padding: {s['wk_pad']}
rows_per_column: 9
column_padding: 40
anchor: center
menu:
"""
    return {
        "which-key/.config/wlr-which-key/config.yaml": head
        + "\n".join(yaml_menu(menu(c), 1))
        + "\n"
    }


def r_mako(c, s):
    t = f"""# {GEN}
default-timeout=10000
font={FONT} {s['font_size'] - 1}
background-color={c['bg']}
text-color={c['fg']}
border-color={c['accent']}
border-size={s['border']}
border-radius={s['radius']}
padding={s['pad']}
margin={max(s['gaps_inner'], 6)}
"""
    return {"../bashrc/.config/mako/config": t}


def r_hammerspoon(c, s):
    body = "".join(f'  {k} = "{c[k]}",\n' for k in COLOR_KEYS)
    return {"hammerspoon/.hammerspoon/colors.lua": f"-- {GEN}\nreturn {{\n{body}}}\n"}


def r_swaylock(c, s):
    h = lambda k: c[k].lstrip("#")
    thick = 6 if s["density"] == "cozy" else 4
    t = f"""# {GEN}
# Wallpaper only until you type; the ring appears on a key press.
image={Path.home()}/.local/share/palette/wallpaper.png
scaling=fill
color={h('bg')}
font={FONT}
font-size=18
ignore-empty-password
show-failed-attempts
indicator-radius=70
indicator-thickness={thick}
inside-color={h('bg')}cc
inside-clear-color={h('bg')}cc
inside-ver-color={h('bg')}cc
inside-wrong-color={h('bg')}cc
ring-color={h('dim')}
ring-clear-color={h('warn')}
ring-ver-color={h('accent2')}
ring-wrong-color={h('urgent')}
key-hl-color={h('accent')}
bs-hl-color={h('urgent')}
caps-lock-key-hl-color={h('warn')}
caps-lock-bs-hl-color={h('urgent')}
line-color=00000000
line-clear-color=00000000
line-ver-color=00000000
line-wrong-color=00000000
separator-color=00000000
text-color={h('fg')}
text-clear-color={h('warn')}
text-ver-color={h('accent2')}
text-wrong-color={h('urgent')}
text-caps-lock-color={h('warn')}
"""
    return {"swaylock/.config/swaylock/config": t}


def r_gtklock(c, s):
    """A conventional lock screen: clock, date, avatar + name, password box (needs the gtklock package)."""
    import glob

    mods = sorted(
        glob.glob("/usr/lib/*/gtklock/*userinfo*.so")
        + glob.glob("/usr/lib/gtklock/*userinfo*.so")
    )
    modline = f"modules={mods[0]}\n" if mods else ""
    rad = max(s["radius"], 8)
    ini = f"""# {GEN}
[main]
background={Path.home()}/.local/share/palette/lock-frame.png
style={Path.home()}/.config/gtklock/style.css
time-format=%H:%M
date-format=%A, %d %B
idle-hide=true
idle-timeout=20
{modline}
[userinfo]
under-clock=true
"""
    a = lambda k, al: f"alpha({c[k]}, {al})"
    css = f"""/* {GEN} */
* {{ font-family: "{FONT}"; color: {c['fg']}; }}
window {{ background-color: {c['bg']}; }}
#clock-label {{ font-size: 96px; font-weight: bold; color: {c['accent']}; margin-bottom: 4px; }}
#date-label {{ font-size: 22px; color: {c['accent2']}; margin-bottom: 36px; }}
#user-image, #userinfo-image {{ border-radius: 999px; margin-bottom: 10px; }}
#user-name, #userinfo-name, #user-label {{ font-size: 20px; margin-bottom: 14px; }}
#input-label {{ color: {c['dim']}; font-size: 14px; }}
#input-field {{
    min-width: 320px; padding: 10px 16px; border-radius: {rad}px;
    background-color: {a('bg', 0.85)}; border: {s['border'] + 1}px solid {c['accent']};
    color: {c['fg']}; caret-color: {c['accent']}; font-size: 18px;
}}
#input-field:focus {{ border-color: {c['accent2']}; }}
#error-label {{ color: {c['urgent']}; margin-top: 12px; font-size: 16px; }}
#unlock-button {{ background: transparent; border: none; color: {c['accent']}; }}
"""
    d = "gtklock/.config/gtklock/"
    return {d + "config.ini": ini, d + "style.css": css}


def r_gtk(c, s):
    n = {
        "accent_bg_color": c["accent"],
        "accent_fg_color": c["bg"],
        "accent_color": c["accent"],
        "window_bg_color": c["bg"],
        "window_fg_color": c["fg"],
        "view_bg_color": c["bg"],
        "view_fg_color": c["fg"],
        "headerbar_bg_color": c["bg"],
        "headerbar_fg_color": c["fg"],
        "headerbar_border_color": c["ansi"][0],
        "card_bg_color": c["ansi"][0],
        "card_fg_color": c["fg"],
        "popover_bg_color": c["bg"],
        "popover_fg_color": c["fg"],
        "sidebar_bg_color": c["bg"],
        "sidebar_fg_color": c["fg"],
        "dialog_bg_color": c["bg"],
        "dialog_fg_color": c["fg"],
        "destructive_bg_color": c["urgent"],
        "destructive_color": c["urgent"],
        "error_color": c["urgent"],
        "warning_color": c["warn"],
        "success_color": c["ansi"][2],
        # GTK3 theme names
        "theme_bg_color": c["bg"],
        "theme_fg_color": c["fg"],
        "theme_base_color": c["bg"],
        "theme_text_color": c["fg"],
        "theme_selected_bg_color": c["accent"],
        "theme_selected_fg_color": c["bg"],
    }
    css = f"/* {GEN} */\n" + "".join(f"@define-color {k} {v};\n" for k, v in n.items())
    h = Path.home() / ".config"
    return {str(h / "gtk-3.0/gtk.css"): css, str(h / "gtk-4.0/gtk.css"): css}
