local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("vim-options")
require("vim-keybinds")

-- require("lazy").setup("plugins", { debug = true }, { change_detection = { notify = false } })
require("lazy").setup("plugins", {}, { change_detection = { notify = false } })

-- My lazily added custom functions
require("jump-to-matching-line")

-- Lazily added keymaps for folke/persistence.nvim
vim.keymap.set("n", "<leader>qs", function()
    require("persistence").load()
end)
vim.keymap.set("n", "<leader>qS", function()
    require("persistence").select()
end)
vim.keymap.set("n", "<leader>ql", function()
    require("persistence").load({ last = true })
end)
vim.keymap.set("n", "<leader>qd", function()
    require("persistence").stop()
end)
