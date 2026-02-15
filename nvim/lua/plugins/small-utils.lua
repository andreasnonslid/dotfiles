-- Small utility plugins that don't need their own files
return {
  -- Vim repeat - repeat plugin commands with .
  {
    "tpope/vim-repeat",
    event = "VeryLazy",
  },

  -- Indent guides - LazyVim has this built-in, but if you want explicit control:
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "LazyFile",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { enabled = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    },
  },
} 