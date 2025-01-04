local my_theme = "noctishc"

return {
    {
        "iagorrr/noctishc.nvim",
        opts = {},
        config = function(_, opts)
            require(my_theme).setup(opts)
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
        config = function()
            require("lualine").setup({
                theme = my_theme,
            })
        end,
    },
}
