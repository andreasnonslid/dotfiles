return {
    {
        "lewis6991/gitsigns.nvim",

        config = function()
            require("gitsigns").setup()

            vim.keymap.set(
                "n",
                "<leader>gt",
                ":Gitsigns toggle_current_line_blame<CR>",
                { desc = "[G]it [T]oggle line blame" }
            )
        end,
    },
}
