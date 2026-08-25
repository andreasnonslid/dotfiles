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
vim.opt.timeoutlen = 400
vim.opt.scrolloff = 10
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Statusline (Neovim 0.12 default: filename, mode, diagnostics, LSP progress)
vim.opt.laststatus = 3
vim.opt.ruler = false
vim.opt.showmode = false

-- Folding (treesitter-based; open expanded, toggle with <leader>z)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldtext = "" -- show actual line content when folded (nvim 0.10+)

-- Diff (built-in engine; diffview.nvim drives it, see lua/plugins/diff.lua)
-- linematch re-aligns lines inside a changed hunk so a one-word edit highlights
-- as one word instead of two whole replaced lines; histogram + indent-heuristic
-- pick hunk boundaries that follow code structure rather than the first match.
vim.opt.diffopt = {
  "internal",
  "filler",
  "closeoff",
  "vertical",
  "algorithm:histogram",
  "indent-heuristic",
  "linematch:60",
  "context:6",
}
vim.opt.fillchars:append({ diff = "╱" })

-- Disable animations
vim.opt.smoothscroll = false
vim.g.snacks_animate = false
vim.g.snacks_scroll = false
vim.g.neovide_scroll_animation_length = 0
vim.g.neovide_cursor_animation_length = 0
