-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Language setting
vim.cmd("language en_US.utf8")

-- SET SNACKS AS DEFAULT PICKER
vim.g.lazyvim_picker = "snacks"

-- DISABLE ALL SMOOTH SCROLLING AND ANIMATIONS
vim.opt.smoothscroll = false -- Disable Neovim's native smooth scrolling
vim.opt.scrolloff = 10 -- Your preferred scrolloff, but no smooth scrolling

-- Disable any animation-related settings
vim.g.neovide_scroll_animation_length = 0 -- Disable neovide scroll animations (if using neovide)
vim.g.neovide_cursor_animation_length = 0 -- Disable neovide cursor animations

-- Ensure snacks doesn't override these settings
vim.g.snacks_animate = false
vim.g.snacks_scroll = false

-- Your custom options that differ from LazyVim defaults
vim.opt.tabstop = 4 -- LazyVim uses 2, you prefer 4
vim.opt.shiftwidth = 4 -- LazyVim uses 2, you prefer 4
vim.opt.wrap = false -- LazyVim default is false, but making it explicit

-- Custom cursor line highlight (your preference)
-- vim.cmd("highlight CursorLine cterm=NONE ctermbg=236 ctermfg=NONE guibg=Grey40")
vim.opt.cursorline = true

-- DISABLE TABS AND TABLINE
vim.opt.showtabline = 0 -- Never show tabline (0 = never, 1 = only when multiple tabs, 2 = always)
vim.o.showtabline = 0 -- Ensure it's also set in global options

-- LazyVim already sets these, but your explicit preferences:
-- vim.opt.relativenumber = true  -- ✅ LazyVim default
-- vim.opt.number = true          -- ✅ LazyVim default
-- vim.opt.mouse = "a"            -- ✅ LazyVim default
-- vim.opt.breakindent = true     -- ✅ LazyVim default
-- vim.opt.undofile = true        -- ✅ LazyVim default
-- vim.opt.signcolumn = "yes"     -- ✅ LazyVim default
-- vim.opt.updatetime = 200       -- ✅ LazyVim default (you had 250)
-- vim.opt.timeoutlen = 300       -- ✅ LazyVim default
-- vim.opt.list = true            -- ✅ LazyVim default
-- vim.opt.splitright = true      -- ✅ LazyVim default
-- vim.opt.splitbelow = true      -- ✅ LazyVim default
-- vim.opt.inccommand = "nosplit" -- ✅ LazyVim default (you had "split")
-- vim.opt.cursorline = true      -- ✅ LazyVim default
-- vim.opt.hlsearch = true        -- ✅ LazyVim default
-- vim.opt.autoindent = true      -- ✅ LazyVim default
-- vim.opt.expandtab = true       -- ✅ LazyVim default
-- vim.opt.ignorecase = true      -- ✅ LazyVim default
-- vim.opt.smartcase = true       -- ✅ LazyVim default
-- vim.opt.termguicolors = true   -- ✅ LazyVim default

-- LazyVim sets these differently:
-- vim.opt.listchars = LazyVim uses different chars
-- vim.opt.backspace = LazyVim doesn't set this (uses default)
-- vim.opt.timeout = LazyVim doesn't set this explicitly

vim.o.autoread = true
