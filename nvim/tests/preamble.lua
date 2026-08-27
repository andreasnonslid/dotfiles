--- Loaded via --cmd, before init.lua, so it can see every mapping the config
--- registers. Records who claimed which key; keymaps_spec reads the result.
local orig = vim.keymap.set
_G.__keymap_sets = {}
vim.keymap.set = function(mode, lhs, rhs, opts)
  local modes = type(mode) == "table" and mode or { mode }
  local info = debug.getinfo(2, "Sl")
  local path = info and info.short_src or "?"
  local src = path .. ":" .. (info and info.currentline or 0)
  for _, m in ipairs(modes) do
    local key = m .. "  " .. lhs
    local seen = _G.__keymap_sets[key] or {}
    seen[#seen + 1] = {
      src = src,
      path = path,
      buflocal = opts ~= nil and opts.buffer ~= nil,
      desc = opts and opts.desc,
    }
    _G.__keymap_sets[key] = seen
  end
  return orig(mode, lhs, rhs, opts)
end
