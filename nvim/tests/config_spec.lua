-- The config loads clean, and every plugin it declares is actually there.
local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local t = dofile(here .. "/init.lua")

local plugin_errors = {}
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyPluginError",
  callback = function(args)
    plugin_errors[#plugin_errors + 1] = vim.inspect(args.data)
  end,
})

require("lazy").install({ show = false, wait = true })
vim.cmd("doautocmd User VeryLazy")
vim.wait(500)

t.check("no plugin load errors", #plugin_errors == 0, table.concat(plugin_errors, " | "))

local plugins = require("lazy.core.config").plugins
for name, plugin in pairs(plugins) do
  t.check(("%s is installed on disk"):format(name), vim.fn.isdirectory(plugin.dir) == 1, plugin.dir)
end

-- Options the rest of the config assumes. Each of these has been changed by
-- accident at least once in some config somewhere; they are cheap to pin.
t.check("leader is space", vim.g.mapleader == " ", vim.g.mapleader)
t.check("undofile on", vim.o.undofile == true)
t.check("folds are treesitter", vim.o.foldexpr:find("treesitter", 1, true) ~= nil, vim.o.foldexpr)
t.check("folds start open", vim.o.foldlevelstart >= 99, vim.o.foldlevelstart)
t.check("termguicolors on", vim.o.termguicolors == true)

-- One icon provider, not two. mini.icons mocks the nvim-web-devicons interface,
-- so oil (and anything else that probes for it) is served without a second
-- plugin being installed. Asserted in both directions: the mock has to actually
-- answer, or oil loses its icons silently.
t.check("nvim-web-devicons is not installed", plugins["nvim-web-devicons"] == nil)
local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
t.check("the nvim-web-devicons interface still resolves", devicons_ok, devicons)
t.check("...and it answers get_icon", devicons_ok and type(devicons.get_icon) == "function")

-- LSP servers, derived from the config rather than restated here. A hardcoded
-- list is a list that goes stale: add a sixth server and a copy in this file
-- would keep asserting the old five and report success.
--
-- Checked in both directions, because either half can drift alone: a config
-- file with no entry in config.lsp is dead weight that never loads, and an
-- entry with no file makes config.lsp warn at every startup.
local declared = {}
for _, name in ipairs(require("config.lsp").servers) do
  declared[name] = true
end
t.check("config.lsp declares at least one server", next(declared) ~= nil)

local lsp_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lsp")
local on_disk = {}
for name, kind in vim.fs.dir(lsp_dir) do
  if kind == "file" and name:match("%.lua$") then
    on_disk[name:gsub("%.lua$", "")] = true
  end
end

for name in pairs(declared) do
  t.check(("config.lsp %q has an lsp/%s.lua"):format(name, name), on_disk[name] == true)
  if on_disk[name] then
    local ok, cfg = pcall(dofile, vim.fs.joinpath(lsp_dir, name .. ".lua"))
    t.check(("lsp/%s.lua returns a table"):format(name), ok and type(cfg) == "table", cfg)
  end
end
for name in pairs(on_disk) do
  t.check(("lsp/%s.lua is declared in config.lsp"):format(name), declared[name] == true)
end

t.finish()
