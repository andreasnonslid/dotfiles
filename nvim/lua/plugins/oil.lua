-- Oil.nvim - A vim-like file manager
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      -- Configuration options here
      default_file_explorer = true,
      columns = {
        "icon",
        "permissions",
        "size",
        "mtime",
      },
      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = false,
      prompt_save_on_select_new_entry = true,
      cleanup_delay_ms = 2000,
      lsp_file_methods = {
        timeout_ms = 1000,
        autosave_changes = false,
      },
      constrain_cursor = "editable",
      experimental_watch_for_changes = false,
      use_default_keymaps = true,
      keymaps = {
        -- Free up <C-h> and <C-l> for window navigation
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-r>"] = "actions.refresh",
        ["<C-s>"] = "actions.select_vsplit",
        ["<leader>wa"] = {
          desc = "Workspace: Add this dir",
          callback = function()
            local dir = require("oil").get_current_dir()
            require("config.workspaces").add_dir(dir)
          end,
        },
      },
    })

    -- Keymap to open oil
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
  end,
}
