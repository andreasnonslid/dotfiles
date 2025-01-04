return {
    {
        "mbbill/undotree",
        config = function()
            -- Persistent undo configuration
            if vim.fn.has("persistent_undo") == 1 then
                local undodir = vim.fn.expand("~/.undodir")
                if not vim.fn.isdirectory(undodir) then
                    vim.fn.mkdir(undodir, "p")
                end
                vim.opt.undodir = undodir
                vim.opt.undofile = true
            end

            vim.keymap.set(
                "n",
                "<leader>u",
                vim.cmd.UndotreeToggle,
                { desc = "[U]ndo Tree" }
            )
        end,
    },
}
