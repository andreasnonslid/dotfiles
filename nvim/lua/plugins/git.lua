return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end
        map("]H", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next Git Hunk")
        map("[H", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev Git Hunk")
        map("<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<CR>", "Toggle Git Blame")
        map("<leader>gp", gs.preview_hunk, "Preview Hunk")
        map("<leader>gS", gs.stage_hunk, "Stage Hunk")
        map("<leader>gR", gs.reset_hunk, "Reset Hunk")
      end,
    },
  },
}
