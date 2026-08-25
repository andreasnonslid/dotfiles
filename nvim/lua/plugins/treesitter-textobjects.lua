return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install")
        .install({
          "lua",
          "python",
          "c",
          "cpp",
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "bash",
        })
        :wait(300000)
    end,
    event = { "BufReadPost", "BufNewFile" },
    -- nvim-treesitter v2: no setup() for highlight/indent/textobjects
    -- NeoVim 0.11 handles treesitter highlight natively via vim.treesitter
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      -- ]c/[c are the built-in next/prev diff change. Hand them back while a
      -- window is in diff mode -- same guard gitsigns uses for ]H/[H -- so
      -- reviewing a diff does not silently jump by class instead of by hunk.
      local function diff_aware(key, fn)
        return function()
          if vim.wo.diff then
            vim.cmd.normal({ key, bang = true })
          else
            fn()
          end
        end
      end

      -- Select
      vim.keymap.set({ "x", "o" }, "af", function()
        select.select_textobject("@function.outer", "textobjects")
      end, { desc = "around function" })
      vim.keymap.set({ "x", "o" }, "if", function()
        select.select_textobject("@function.inner", "textobjects")
      end, { desc = "inside function" })
      vim.keymap.set({ "x", "o" }, "ac", function()
        select.select_textobject("@class.outer", "textobjects")
      end, { desc = "around class" })
      vim.keymap.set({ "x", "o" }, "ic", function()
        select.select_textobject("@class.inner", "textobjects")
      end, { desc = "inside class" })
      vim.keymap.set({ "x", "o" }, "aa", function()
        select.select_textobject("@parameter.outer", "textobjects")
      end, { desc = "around argument" })
      vim.keymap.set({ "x", "o" }, "ia", function()
        select.select_textobject("@parameter.inner", "textobjects")
      end, { desc = "inside argument" })

      -- Move
      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer")
      end, { desc = "Next function" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer")
      end, { desc = "Prev function" })
      vim.keymap.set(
        { "n", "x", "o" },
        "]c",
        diff_aware("]c", function()
          move.goto_next_start("@class.outer")
        end),
        { desc = "Next class / diff change" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "[c",
        diff_aware("[c", function()
          move.goto_previous_start("@class.outer")
        end),
        { desc = "Prev class / diff change" }
      )
      vim.keymap.set({ "n", "x", "o" }, "]a", function()
        move.goto_next_start("@parameter.inner")
      end, { desc = "Next argument" })
      vim.keymap.set({ "n", "x", "o" }, "[a", function()
        move.goto_previous_start("@parameter.inner")
      end, { desc = "Prev argument" })

      -- Swap
      vim.keymap.set("n", "<leader>a", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap with next argument" })
      vim.keymap.set("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap with prev argument" })
    end,
  },
}
