return {
  -- Icons (used by which-key, trouble, snacks, etc.)
  { "echasnovski/mini.icons", lazy = false, opts = {} },

  -- Auto-close brackets, quotes, etc.
  { "echasnovski/mini.pairs", event = "InsertEnter", opts = {} },

  -- Better a/i text objects (smarter than built-in)
  { "echasnovski/mini.ai", event = { "BufReadPost", "BufNewFile" }, opts = {} },

  -- Surround operations: gsa (add), gsd (delete), gsr (replace), gsf/gsh (find)
  { "echasnovski/mini.surround", event = { "BufReadPost", "BufNewFile" }, opts = {} },
}
