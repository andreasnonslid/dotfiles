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
}
