-- Custom theme configuration (overrides LazyVim's default tokyonight)
local my_theme = "noctishc"

return {
  -- Custom theme
  {
    "iagorrr/noctishc.nvim",
    opts = {},
    config = function(_, opts)
      require(my_theme).setup(opts)
    end,
  },

  -- Configure LazyVim to use our custom theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = my_theme,
    },
  },

  -- Configure lualine to use our theme
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      theme = my_theme,
    },
  },
} 