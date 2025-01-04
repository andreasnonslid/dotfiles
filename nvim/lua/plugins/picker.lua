return {
  {
    "folke/snacks.nvim",
    keys = {
      -- General utilities
      {
        "<leader>fh",
        function()
          require("snacks").picker.help()
        end,
        desc = "[F]ind [H]elp",
      },
      {
        "<leader>fk",
        function()
          require("snacks").picker.keymaps()
        end,
        desc = "[F]ind [K]eymaps",
      },
      {
        "<leader>fs",
        function()
          require("snacks").picker.lsp_symbols()
        end,
        desc = "[F]ind [S]ymbols",
      },
      {
        "<leader>fd",
        function()
          require("snacks").picker.diagnostics()
        end,
        desc = "[F]ind [D]iagnostics",
      },
      {
        "<leader>fr",
        function()
          require("snacks").picker.resume()
        end,
        desc = "[F]ind [R]esume",
      },
      {
        "<leader>f.",
        function()
          require("snacks").picker.recent()
        end,
        desc = "[F]ind Recent Files",
      },
      {
        "<leader>f<leader>",
        function()
          require("snacks").picker.buffers()
        end,
        desc = "[ ] Find existing buffers",
      },

      -- Repo root operations with better mnemonics - <leader>F*
      {
        "<leader>Ff",
        function()
          require("snacks").picker.files()
        end,
        desc = "[F]ind [F]iles in repo",
      },
      {
        "<leader>Fg",
        function()
          require("snacks").picker.grep()
        end,
        desc = "[F]ind by [G]rep in repo",
      },
      {
        "<leader>Fw",
        function()
          require("snacks").picker.grep_word()
        end,
        desc = "[F]ind current [W]ord in repo",
      },
      {
        "<leader>FG",
        function()
          require("snacks").picker.git_files()
        end,
        desc = "[F]ind [G]it files in repo",
      },
      {
        "<leader>F<space>",
        function()
          require("snacks").picker.git_files()
        end,
        desc = "[F]ind git-tracked files",
      },

      -- Local (cwd) operations - <leader>f*
      {
        "<leader>ff",
        function()
          require("snacks").picker.files({ root = false })
        end,
        desc = "[f]ind [f]iles in cwd",
      },
      {
        "<leader>fg",
        function()
          require("snacks").picker.grep({ root = false })
        end,
        desc = "[f]ind by [g]rep in cwd",
      },
      {
        "<leader>fw",
        function()
          require("snacks").picker.grep_word({ root = false })
        end,
        desc = "[f]ind current [w]ord in cwd",
      },

      -- Git operations
      {
        "<leader>gf",
        function()
          require("snacks").picker.git_files()
        end,
        desc = "[G]it [F]iles",
      },
      {
        "<leader>gc",
        function()
          require("snacks").picker.git_commits()
        end,
        desc = "[G]it [C]ommits",
      },
      {
        "<leader>gb",
        function()
          require("snacks").picker.git_branches()
        end,
        desc = "[G]it [B]ranches",
      },
      {
        "<leader>gs",
        function()
          require("snacks").picker.git_status()
        end,
        desc = "[G]it [S]tatus",
      },

      -- Search operations
      {
        "<leader>s/",
        function()
          require("snacks").picker.search_history()
        end,
        desc = "[S]earch [/] history",
      },
      {
        "<leader>s:",
        function()
          require("snacks").picker.command_history()
        end,
        desc = "[S]earch [:]command history",
      },
      {
        "<leader>sb",
        function()
          require("snacks").picker.lines()
        end,
        desc = "[S]earch [B]uffer lines",
      },
      {
        "<leader>sg",
        function()
          require("snacks").picker.grep()
        end,
        desc = "[S]earch by [G]rep",
      },
      {
        "<leader>sj",
        function()
          require("snacks").picker.jumps()
        end,
        desc = "[S]earch [J]umps",
      },
      {
        "<leader>sk",
        function()
          require("snacks").picker.keymaps()
        end,
        desc = "[S]earch [K]eymaps",
      },
      {
        "<leader>sl",
        function()
          require("snacks").picker.loclist()
        end,
        desc = "[S]earch [L]oclist",
      },
      {
        "<leader>sm",
        function()
          require("snacks").picker.marks()
        end,
        desc = "[S]earch [M]arks",
      },
      {
        "<leader>sn",
        function()
          require("snacks").picker.notifications()
        end,
        desc = "[S]earch [N]otifications",
      },
      {
        "<leader>sr",
        function()
          require("snacks").picker.resume()
        end,
        desc = "[S]earch [R]esume",
      },
      {
        "<leader>sq",
        function()
          require("snacks").picker.qflist()
        end,
        desc = "[S]earch [Q]uickfix",
      },
      {
        "<leader>st",
        function()
          require("snacks").picker.todo_comments()
        end,
        desc = "[S]earch [T]odo comments",
      },

      -- Visual mode search
      {
        "<leader>sg",
        function()
          require("snacks").picker.grep()
        end,
        desc = "[S]earch [G]rep selection",
        mode = "v",
      },
      {
        "<leader>sw",
        function()
          require("snacks").picker.grep_word()
        end,
        desc = "[S]earch [W]ord selection",
        mode = "v",
      },
    },
  },
}
