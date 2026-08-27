-- Keymap invariants. This is the spec most likely to catch a real regression:
-- keymap breakage is silent, survives startup, and only shows up as "why did
-- that key stop doing what it used to".
local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local t = dofile(here .. "/init.lua")

require("lazy").install({ show = false, wait = true })
vim.cmd.edit(vim.fn.tempname() .. ".lua") -- trigger BufReadPost/BufNewFile lazy loads
vim.cmd("doautocmd User VeryLazy")
vim.wait(500)

-- 1. Builtins this config must not silently take over. Each entry is a key
--    whose default behaviour is load-bearing somewhere in the README's
--    workflow; if one starts showing up as mapped, that was a decision and it
--    should be a deliberate one, made here.
local must_stay_native = {
  { "n", "<C-]>", "jump to tag" },
  { "n", "<C-t>", "pop tag stack" },
  { "n", "g<C-]>", "tjump" },
  { "n", "<C-w>]", "tag in split" },
  { "n", "<C-w>}", "preview tag" },
  { "n", "<C-o>", "jumplist back" },
  { "n", "<C-i>", "jumplist forward" },
  { "n", "do", "diffget" },
  { "n", "dp", "diffput" },
  { "n", "zR", "open all folds" },
  { "n", "zM", "close all folds" },
  { "n", ".", "repeat" },
  { "n", "u", "undo" },
}
for _, entry in ipairs(must_stay_native) do
  local mode, key, what = entry[1], entry[2], entry[3]
  local mapped = vim.fn.maparg(vim.keycode(key), mode)
  t.check(("%s stays native (%s)"):format(key, what), mapped == "", mapped)
end

-- Builtins this config knowingly gives up, and to whom. Asserted rather than
-- merely documented so that both directions are caught: the owner dropping the
-- mapping, or a different plugin quietly taking it over.
local known_shadowed = {
  { "n", "g]", "mini/ai.lua", "tselect -- use g<C-]> (tjump) instead" },
}
for _, entry in ipairs(known_shadowed) do
  local mode, key, owner, what = entry[1], entry[2], entry[3], entry[4]
  local mapped = vim.fn.maparg(vim.keycode(key), mode)
  t.check(
    ("%s is still shadowed by %s (gives up %s)"):format(key, owner, what),
    mapped:find(owner, 1, true) ~= nil,
    mapped
  )
end

-- 2. No two *global* mappings in THIS CONFIG claim the same key. A buffer-local
--    mapping layered over a global one is normal (LspAttach, gitsigns, oil) and
--    is not a collision; two globals are, and the later one silently wins.
--
--    Scoped to files under stdpath("config") on purpose. lazy.nvim legitimately
--    sets each `keys =` lhs twice -- once as the load-me stub, once for real
--    after the plugin loads -- and plugin-internal mappings are not this repo's
--    to fix. Counting them would make this spec cry wolf on every run, which is
--    worse than not having it.
local config_dir = vim.fn.stdpath("config")
for key, claims in pairs(_G.__keymap_sets or {}) do
  local globals = vim.tbl_filter(function(c)
    return not c.buflocal and c.path and c.path:find(config_dir, 1, true) == 1
  end, claims)
  if #globals > 1 then
    local srcs = table.concat(
      vim.tbl_map(function(c)
        return (c.src:gsub("^" .. vim.pesc(config_dir) .. "/", ""))
      end, globals),
      " and "
    )
    t.check(("%q claimed once globally"):format(key), false, srcs)
  end
end

-- 3. Every <leader> mapping is discoverable in which-key. A missing desc is not
--    a bug, but it is the difference between a key you remember and one you
--    lose, and it costs nothing to keep at zero.
local leader = vim.g.mapleader == " " and " " or vim.g.mapleader
for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
  if map.lhs:sub(1, #leader) == leader and #map.lhs > #leader then
    t.check(("<leader>%s has a desc"):format(map.lhs:sub(#leader + 1)), (map.desc or "") ~= "")
  end
end

t.finish()
