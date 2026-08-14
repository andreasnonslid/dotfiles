return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    animate = { enabled = false },
    scroll = { enabled = false },
    dashboard = { enabled = false },
    notifier = {
      enabled = true,
      filter = function(n)
        local msg = n.msg or ""
        return not msg:match("^Command failed:")
      end,
    },
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = false },
    words = { enabled = false },
    terminal = { enabled = true },
    picker = {
      sources = {
        files = { notify = false },
        grep = { notify = false },
        explorer = { notify = false },
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
  end,
  keys = {
    -- Find (repo root)
    {
      "<leader>Ff",
      function()
        require("snacks").picker.files()
      end,
      desc = "Find Files (repo)",
    },
    {
      "<leader>Fg",
      function()
        require("snacks").picker.grep()
      end,
      desc = "Grep (repo)",
      mode = { "n", "v" },
    },
    {
      "<leader>Fw",
      function()
        require("snacks").picker.grep_word()
      end,
      desc = "Grep Word (repo)",
    },
    {
      "<leader>FG",
      function()
        require("snacks").picker.git_files()
      end,
      desc = "Git Files (repo)",
    },
    -- Find (workspace: root + extra search dirs; LSP/compile stay on root)
    {
      "<leader>ff",
      function()
        require("config.workspaces").pick_files()
      end,
      desc = "Find Files (workspace)",
    },
    {
      "<leader>fg",
      function()
        require("config.workspaces").pick_grep()
      end,
      desc = "Grep (workspace)",
      mode = { "n", "v" },
    },
    {
      "<leader>fw",
      function()
        require("config.workspaces").pick_grep_word()
      end,
      desc = "Grep Word (workspace)",
    },
    -- General find
    {
      "<leader>fh",
      function()
        require("snacks").picker.help()
      end,
      desc = "Find Help",
    },
    {
      "<leader>fk",
      function()
        require("snacks").picker.keymaps()
      end,
      desc = "Find Keymaps",
    },
    {
      "<leader>fs",
      function()
        require("snacks").picker.lsp_symbols()
      end,
      desc = "Find Symbols",
    },
    {
      "<leader>fd",
      function()
        require("snacks").picker.diagnostics()
      end,
      desc = "Find Diagnostics",
    },
    {
      "<leader>fD",
      function()
        require("snacks").picker.diagnostics({ filter = { buf = 0 } })
      end,
      desc = "Find Diagnostics (buffer)",
    },
    {
      "<leader>fr",
      function()
        require("snacks").picker.resume()
      end,
      desc = "Resume Picker",
    },
    {
      "<leader>f.",
      function()
        require("snacks").picker.recent()
      end,
      desc = "Recent Files",
    },
    {
      "<leader>f<leader>",
      function()
        require("snacks").picker.buffers()
      end,
      desc = "Find Buffers",
    },
    -- Git
    {
      "<leader>gf",
      function()
        require("snacks").picker.git_files()
      end,
      desc = "Git Files",
    },
    {
      "<leader>gc",
      function()
        require("snacks").picker.git_commits()
      end,
      desc = "Git Commits",
    },
    {
      "<leader>gb",
      function()
        require("snacks").picker.git_branches()
      end,
      desc = "Git Branches",
    },
    {
      "<leader>gs",
      function()
        require("snacks").picker.git_status()
      end,
      desc = "Git Status",
    },
    -- Search
    {
      "<leader>s/",
      function()
        require("snacks").picker.search_history()
      end,
      desc = "Search History",
    },
    {
      "<leader>s:",
      function()
        require("snacks").picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>sb",
      function()
        require("snacks").picker.lines()
      end,
      desc = "Buffer Lines",
    },
    {
      "<leader>sj",
      function()
        require("snacks").picker.jumps()
      end,
      desc = "Jumps",
    },
    {
      "<leader>sl",
      function()
        require("snacks").picker.loclist()
      end,
      desc = "Location List",
    },
    {
      "<leader>sm",
      function()
        require("snacks").picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>sn",
      function()
        require("snacks").picker.notifications()
      end,
      desc = "Notifications",
    },
    {
      "<leader>sq",
      function()
        require("snacks").picker.qflist()
      end,
      desc = "Quickfix",
    },
    {
      "<leader>st",
      function()
        require("snacks").picker.grep({
          search = "TODO|FIXME|HACK|XXX",
          title = "Todo comments",
        })
      end,
      desc = "Todo Comments",
    },
    {
      "<F4>",
      function()
        require("snacks").terminal()
      end,
      desc = "Terminal (toggle)",
    },
    {
      "<leader>gg",
      function()
        local root = require("snacks").git.get_root()
        require("snacks").terminal("lazygit", { cwd = root or vim.fn.getcwd() })
      end,
      desc = "Lazygit",
    },
    {
      "<leader>sw",
      function()
        require("snacks").picker.grep_word()
      end,
      desc = "Search Word",
      mode = "v",
    },
  },
}
