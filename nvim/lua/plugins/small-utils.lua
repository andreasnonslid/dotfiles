-- Small utility plugins that don't need their own files
return {
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
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
        },
      },
    },
  },
} 