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

-- Statusline (native; lualine removed)
vim.opt.laststatus = 3
vim.opt.ruler = false
vim.opt.showmode = false
function _G.dotfiles_statusline()
  local mode = vim.api.nvim_get_mode().mode
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
  if name == "" then
    name = "[No Name]"
  end
  local diag = ""
  local counts = vim.diagnostic.count(0)
  local total = 0
  for _, n in pairs(counts) do
    total = total + n
  end
  if total > 0 then
    diag = string.format(" 󰅙%d", total)
  end
  return string.format(" %s │ %s%s ", mode, name, diag)
end
vim.opt.statusline = "%{v:lua._G.dotfiles_statusline()}"

-- Folding (treesitter-based; open expanded, toggle on <C-CR>)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldtext = "" -- show actual line content when folded (nvim 0.10+)

-- Disable animations
vim.opt.smoothscroll = false
vim.g.snacks_animate = false
vim.g.snacks_scroll = false
vim.g.neovide_scroll_animation_length = 0
vim.g.neovide_cursor_animation_length = 0
