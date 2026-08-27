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

-- Every server named in config.lsp has a config file that loads.
for _, name in ipairs({ "clangd", "pyright", "lua_ls", "ruff", "bashls" }) do
  local found = vim.api.nvim_get_runtime_file("lsp/" .. name .. ".lua", false)[1]
  t.check(("lsp/%s.lua exists"):format(name), found ~= nil)
  if found then
    local ok, cfg = pcall(dofile, found)
    t.check(("lsp/%s.lua returns a table"):format(name), ok and type(cfg) == "table", cfg)
  end
end

t.finish()
