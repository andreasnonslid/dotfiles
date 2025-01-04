-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Your custom keymaps that don't conflict with LazyVim

-- Save buffer (LazyVim has <C-s>, but you prefer <leader>w)
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "[W]rite buffer" })

-- Clipboard operations
vim.keymap.set("v", "<leader>y", '"+y', { desc = "[Y]ank to clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "[P]aste from clipboard" })

-- Utility keymaps
vim.keymap.set("n", "<leader>cm", ":let @/ = ''<CR>:%s/\\r//g<CR>", {
  desc = "Removes [C]opied line endings [M]^ from file",
})

-- Copy buffer information to clipboard
vim.keymap.set("n", "<leader>ybn", ":let @+ = expand('%')<CR>", {
  desc = "[Y]ank [B]uffer [N]ame to clipboard",
})
vim.keymap.set("n", "<leader>yfp", ":let @+ = expand('%:p')<CR>", {
  desc = "[Y]ank [F]ile [P]ath to clipboard",
})

-- LazyVim already handles these well:
-- vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>") -- ✅ LazyVim default

-- Notes on LazyVim keymaps to avoid conflicts:
-- - <C-h/j/k/l> are used for window navigation (LazyVim default)
-- - <leader>1-5 are used for harpoon (when harpoon extra is enabled)
-- - <leader>xx, <leader>xX are used for trouble (LazyVim default)
-- - <leader>ff, <leader>fg, <leader>/ are used for finding (LazyVim default)
-- - <leader>qq is used for quit (LazyVim default)
-- - <leader>l is used for Lazy (LazyVim default)

-- LazyVim trouble keymaps (for reference):
-- <leader>xx = "Diagnostics (Trouble)"
-- <leader>xX = "Buffer Diagnostics (Trouble)"  
-- <leader>cs = "Symbols (Trouble)"
-- <leader>cS = "LSP references/definitions/... (Trouble)"
-- <leader>xL = "Location List (Trouble)"
-- <leader>xQ = "Quickfix List (Trouble)"

-- LazyVim has logical groupings:
-- <leader>b* = buffer operations
-- <leader>c* = code operations  
-- <leader>f* = file/find operations
-- <leader>g* = git operations
-- <leader>q* = quit/session operations
-- <leader>s* = search operations
-- <leader>u* = UI toggle operations
-- <leader>x* = diagnostics/quickfix operations
