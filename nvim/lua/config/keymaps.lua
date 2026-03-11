-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window" })

-- Window resize
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase Window Width" })

-- Better up/down with wrapped lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear Search Highlight" })

-- Buffer navigation
vim.keymap.set("n", "[b", "<cmd>bprev<CR>", { desc = "Prev Buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<CR>", { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete Buffer" })

-- Indent in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent Left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent Right" })

-- Quit / Lazy
vim.keymap.set("n", "<leader>qq", "<cmd>qa<CR>", { desc = "Quit All" })
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<CR>", { desc = "Lazy" })

-- Save
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Write Buffer" })
vim.keymap.set("n", "<C-s>", "<cmd>w<CR>", { desc = "Save File" })

-- Clipboard
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to Clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from Clipboard" })

-- Folding
vim.keymap.set("n", "<CR>", "za", { desc = "Toggle Fold" })

-- Utility
vim.keymap.set("n", "<leader>cm", ":let @/ = ''<CR>:%s/\\r//g<CR>", { desc = "Remove Windows Line Endings" })
vim.keymap.set("n", "<leader>ybn", ":let @+ = expand('%')<CR>", { desc = "Yank Buffer Name" })
vim.keymap.set("n", "<leader>yfp", ":let @+ = expand('%:p')<CR>", { desc = "Yank Full Path" })

-- LSP
vim.lsp.enable({ "clangd", "pyright", "lua_ls", "ruff", "bashls" })

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to Definition")
    map("gD", vim.lsp.buf.declaration, "Go to Declaration")
    map("gr", vim.lsp.buf.references, "Go to References")
    map("gi", vim.lsp.buf.implementation, "Go to Implementation")
    map("gy", vim.lsp.buf.type_definition, "Go to Type Definition")
    map("K", vim.lsp.buf.hover, "Hover Documentation")
    map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
    map("[d", function() vim.diagnostic.goto_prev() end, "Prev Diagnostic")
    map("]d", function() vim.diagnostic.goto_next() end, "Next Diagnostic")
    map("<leader>cd", vim.diagnostic.open_float, "Show Diagnostic")
  end,
})
