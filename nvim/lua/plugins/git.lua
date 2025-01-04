-- Git configuration - extends LazyVim's gitsigns with custom keymaps
return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- LazyVim already configures gitsigns, we just add our custom keymaps
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 1000,
        ignore_whitespace = false,
      },
    },
    keys = {
      -- Add our custom git toggle keymap
      { "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<CR>", desc = "[G]it [T]oggle line blame" },
    },
  },
} 