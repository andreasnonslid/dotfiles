"""The ordered list of everything `apply` renders."""

from .render_desktop import (
    r_sway,
    r_waybar,
    r_fuzzel,
    r_whichkey,
    r_mako,
    r_hammerspoon,
    r_swaylock,
    r_gtklock,
    r_gtk,
)
from .render_terminal import r_alacritty, r_starship, r_zellij, r_nvim, r_env

RENDERERS = [
    r_sway,
    r_waybar,
    r_alacritty,
    r_fuzzel,
    r_whichkey,
    r_mako,
    r_hammerspoon,
    r_starship,
    r_zellij,
    r_nvim,
    r_env,
    r_swaylock,
    r_gtklock,
    r_gtk,
]
