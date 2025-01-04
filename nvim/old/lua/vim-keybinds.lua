-- vim.api.nvim_set_keymap("i", "jk", "<ESCAPE>", { noremap = true, silent = true })
vim.api.nvim_set_keymap(
    "n",
    "<leader>w",
    "<cmd>w<CR>",
    { noremap = true, silent = true, desc = "[W]rite buffer" }
)

-- Map <leader>y in visual mode to yank to the system clipboard
vim.api.nvim_set_keymap(
    "v",
    "<leader>y",
    '"+y',
    { noremap = true, silent = true, desc = "[Y]ank to clipboard" }
)

-- Map <leader>p in normal mode to paste from the system clipboard
vim.api.nvim_set_keymap(
    "n",
    "<leader>p",
    '"+p',
    { noremap = true, silent = true, desc = "[P]aste from clipboard" }
)

-- removes the ^M line endings when copying from windows to wsl
vim.api.nvim_set_keymap("n", "<leader>cm", ":let @/ = ''<CR>:%s/\\r//g<CR>", {
    noremap = true,
    silent = true,
    desc = "Removes [C]opied line endings [M]^ from file.",
})

-- copy path to current buffer to system clipboard
vim.api.nvim_set_keymap("n", "<leader>ybn", ":let @+ = expand(' % ')<CR>", {
    noremap = true,
    silent = true,
    desc = "[C]opy buffer [N]ame to clipboard",
})
vim.api.nvim_set_keymap(
    "n",
    "<leader>yfp",
    ":let @+ = expand('%:p')<CR>",
    { noremap = true, silent = true, desc = "[C]opy file [P]ath to clipboard" }
)

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
