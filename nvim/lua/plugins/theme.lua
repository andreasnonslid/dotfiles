return {
  {
    "iagorrr/noctishc.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("noctishc").setup({})
      vim.cmd.colorscheme("noctishc")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "noctishc",
        component_separators = "|",
        section_separators = "",
      },
    },
  },
}
