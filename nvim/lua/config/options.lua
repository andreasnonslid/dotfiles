-- Leader must be set before any keymaps or plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

pcall(vim.cmd, "language en_US.utf8")

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.showtabline = 0
vim.opt.wrap = false
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Editing
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.breakindent = true

-- Search
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "nosplit"

-- Files
vim.opt.undofile = true
vim.opt.autoread = true
vim.opt.swapfile = false

-- Behavior
vim.opt.mouse = "a"
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.scrolloff = 10
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Disable animations
vim.opt.smoothscroll = false
vim.g.snacks_animate = false
vim.g.snacks_scroll = false
vim.g.neovide_scroll_animation_length = 0
vim.g.neovide_cursor_animation_length = 0
