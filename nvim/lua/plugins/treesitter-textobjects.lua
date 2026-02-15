-- Treesitter text objects for language-aware motions and selections
return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "around function" },
            ["if"] = { query = "@function.inner", desc = "inside function" },
            ["ac"] = { query = "@class.outer", desc = "around class" },
            ["ic"] = { query = "@class.inner", desc = "inside class" },
            ["aa"] = { query = "@parameter.outer", desc = "around argument" },
            ["ia"] = { query = "@parameter.inner", desc = "inside argument" },
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = { query = "@function.outer", desc = "Next function" },
            ["]c"] = { query = "@class.outer", desc = "Next class" },
            ["]a"] = { query = "@parameter.inner", desc = "Next argument" },
          },
          goto_previous_start = {
            ["[f"] = { query = "@function.outer", desc = "Prev function" },
            ["[c"] = { query = "@class.outer", desc = "Prev class" },
            ["[a"] = { query = "@parameter.inner", desc = "Prev argument" },
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>a"] = { query = "@parameter.inner", desc = "Swap with next argument" },
          },
          swap_previous = {
            ["<leader>A"] = { query = "@parameter.inner", desc = "Swap with prev argument" },
          },
        },
      },
    },
  },
}
