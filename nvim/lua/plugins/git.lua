-- Git configuration - extends LazyVim's gitsigns with custom keymaps
return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- LazyVim already configures gitsigns, we just add our custom keymaps
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
      },
    },
    keys = {
      -- Remap hunk navigation to [H/]H to free [h/]h for harpoon
      { "]h", false },
      { "[h", false },
      {
        "]H",
        function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            require("gitsigns").nav_hunk("next")
          end
        end,
        desc = "Next Git Hunk",
      },
      {
        "[H",
        function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            require("gitsigns").nav_hunk("prev")
          end
        end,
        desc = "Prev Git Hunk",
      },
      -- Add our custom git toggle keymap
      { "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<CR>", desc = "[G]it [T]oggle line blame" },
    },
  },
}
