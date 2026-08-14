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
      -- Background picker scans (rg with no matches, etc.) still land in history.
      filter = function(notif)
        return not require("config.picker_errors").is_suppressed(notif)
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
    require("config.picker_errors").setup()
  end,
  keys = (function()
    local function ws_pick(picker, extra)
      return function()
        require("snacks").picker[picker](require("config.workspaces").picker_opts(extra))
      end
    end
    return {
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
      ws_pick("files"),
      desc = "Find Files (workspace)",
    },
    {
      "<leader>fg",
      ws_pick("grep"),
      desc = "Grep (workspace)",
      mode = { "n", "v" },
    },
    {
      "<leader>fw",
      ws_pick("grep_word"),
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
      "<leader>fE",
      function()
        require("config.picker_errors").show_errors()
      end,
      desc = "Search/Picker Errors",
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
          search = "TODO|FIXME|HACK|NOTE|XXX",
          title = "Todo comments",
        })
      end,
      desc = "Todo Comments",
    },
    {
      "<leader>sR",
      function()
        require("snacks").picker.grep({ title = "Project search (cfdo %s/old/new/g)" })
      end,
      mode = "n",
      desc = "Project Grep",
    },
    {
      "<leader>xx",
      function()
        require("snacks").picker.diagnostics()
      end,
      desc = "Diagnostics (project)",
    },
    {
      "<leader>xX",
      function()
        require("snacks").picker.diagnostics({ filter = { buf = 0 } })
      end,
      desc = "Diagnostics (buffer)",
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
        require("snacks").terminal("lazygit", { cwd = root })
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
    }
  end)(),
}
