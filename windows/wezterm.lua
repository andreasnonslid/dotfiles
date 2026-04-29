-- WezTerm config: minimal chrome, opensuse-tumbleweed WSL by default,
-- Iosevka Nerd Font.
--
-- Install location on Windows: %USERPROFILE%\.wezterm.lua
-- (or %USERPROFILE%\.config\wezterm\wezterm.lua)

local wezterm = require("wezterm")

return {
  -- Minimal chrome
  enable_tab_bar = false,
  window_decorations = "RESIZE",
  window_padding = { left = 0, right = 0, top = 0, bottom = 0 },

  -- Default to openSUSE Tumbleweed under WSL.
  -- The exact name must match `wsl --list --quiet`. If WezTerm errors on
  -- launch, run that command in PowerShell and replace the suffix.
  default_domain = "WSL:openSUSE-Tumbleweed",

  -- Font
  font = wezterm.font("Iosevka Nerd Font"),
  font_size = 11.0,

  -- Quality of life
  scrollback_lines = 10000,
  hide_mouse_cursor_when_typing = true,
  audible_bell = "Disabled",
  check_for_updates = false,
  default_cursor_style = "SteadyBlock",
}
