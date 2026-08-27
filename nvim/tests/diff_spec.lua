-- Diff review: the built-in engine's settings, and diffview driving it.
local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local t = dofile(here .. "/init.lua")

local gitproj = assert(os.getenv("NVIM_TEST_GITPROJ"), "run via tests/run.sh")
require("lazy").install({ show = false, wait = true })

-- diffview renders through Neovim's own diff engine, so these settings are what
-- decide how a review actually reads.
for _, want in ipairs({ "internal", "linematch:60", "algorithm:histogram", "indent-heuristic" }) do
  t.check(("diffopt carries %s"):format(want), vim.o.diffopt:find(want, 1, true) ~= nil, vim.o.diffopt)
end

-- ]c and [c are the built-in next/prev change. treesitter-textobjects also
-- wants them for class motion; in diff mode the builtin has to win.
local left = vim.fn.tempname() .. ".txt"
local right = vim.fn.tempname() .. ".txt"
vim.fn.writefile({ "l1", "l2", "l3", "l4", "SAME", "l6" }, left)
vim.fn.writefile({ "l1", "l2", "l3", "l4", "CHANGED", "l6" }, right)
vim.cmd.edit(left)
vim.cmd("diffthis")
vim.cmd("vsplit " .. right)
vim.cmd("diffthis")
vim.cmd("wincmd p")
t.check("]c is mapped at all", vim.fn.maparg("]c", "n") ~= "")
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd("normal ]c")
t.check(
  "]c jumps to the change while in diff mode",
  vim.api.nvim_win_get_cursor(0)[1] == 5,
  vim.api.nvim_win_get_cursor(0)[1]
)
vim.cmd("diffoff!")
vim.cmd("only")

-- diffview itself: opens against a real repo with this config's option table.
vim.cmd.cd(gitproj)
vim.fn.writefile({ "int a;", "int added_by_the_spec;" }, vim.fs.joinpath(gitproj, "a.c"))
local ok_open, err_open = pcall(vim.cmd, "DiffviewOpen")
t.check("DiffviewOpen accepted our options", ok_open, err_open)

local lib_ok, lib = pcall(require, "diffview.lib")
t.check("diffview.lib loaded (the toggle keymap needs it)", lib_ok, lib)
if lib_ok then
  t.check(
    "a view opened",
    t.wait_for(function()
      return lib.get_current_view() ~= nil
    end, 10000)
  )
  local cfg = require("diffview.config").get_config()
  t.check(
    "file panel options round-tripped",
    cfg.file_panel.listing_style == "tree" and cfg.file_panel.win_config.width == 32
  )
  t.check("3-way merge layout configured", cfg.view.merge_tool.layout == "diff3_mixed", cfg.view.merge_tool.layout)
  pcall(vim.cmd, "DiffviewClose")
  t.check("the view closed cleanly", lib.get_current_view() == nil)
end

t.finish()
