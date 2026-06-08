local wezterm = require("wezterm")

return {
    -- Minimal chrome, but keep real title bar
    enable_tab_bar = false,
    window_decorations = "TITLE | RESIZE",
    window_padding = { left = 0, right = 0, top = 0, bottom = 0 },

    -- Make title bar visually subtle
    colors = {
        titlebar_background = "#000000",
    },

    -- Default to openSUSE Tumbleweed under WSL.
    default_domain = "WSL:openSUSE-Tumbleweed",

    -- Font
    font = wezterm.font("Iosevka Nerd Font Mono"),
    font_size = 14.0,

    -- QoL
    scrollback_lines = 10000,
    hide_mouse_cursor_when_typing = true,
    audible_bell = "Disabled",
    check_for_updates = false,
    default_cursor_style = "SteadyBlock",
}
