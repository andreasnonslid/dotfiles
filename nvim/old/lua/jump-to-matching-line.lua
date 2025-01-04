-- Map <leader>n to search for the current line
vim.api.nvim_set_keymap(
    "n",
    "<leader>nw",
    [[:let @/='\V\<'.escape(expand('<cword>'), '\\/.*$^~[]').'\>'<CR>/<CR>]],
    { desc = "[N]ext identical [W]ord", noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
    "n",
    "<leader>nl",
    [[:let @/='\V'.escape(getline('.'), '\\/.*$^~[]')<CR>/<CR>]],
    { desc = "[N]ext identical [L]ine", noremap = true, silent = true }
)
