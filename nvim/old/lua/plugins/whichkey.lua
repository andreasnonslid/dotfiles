return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },

        config = function()
            local wk = require("which-key")
            wk.setup({
                preset = { "modern" },
            })

            wk.add({
                { "<leader>f", group = "[F]ind" },
                { "<leader>g", group = "[G]it" },
                { "<leader>t", group = "[T]rouble" },
                { "<leader>y", group = "[Y]ank" },
            })
        end,
    },
    {
        "echasnovski/mini.icons",
        version = "*",
        config = function()
            require("mini.icons").setup()
        end,
    },
}
