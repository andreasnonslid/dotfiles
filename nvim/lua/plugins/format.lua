return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true }) end,
      desc = "Format Buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      python = { "ruff_format", "ruff_organize_imports" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      lua = { "stylua" },
      sh = { "shfmt" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  },
}
