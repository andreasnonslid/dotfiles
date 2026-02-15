-- Formatter configuration via conform.nvim
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        lua = { "stylua" },
      },
    },
  },
}
