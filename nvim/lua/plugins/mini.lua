return {
  -- Icons (used by which-key, snacks, oil, etc.)
  {
    "echasnovski/mini.icons",
    lazy = false,
    opts = {},
    config = function(_, opts)
      require("mini.icons").setup(opts)
      -- Serve the nvim-web-devicons interface from mini.icons, so plugins that
      -- probe for it (oil) are satisfied without a second icon provider being
      -- installed to say the same things in a different table.
      require("mini.icons").mock_nvim_web_devicons()
    end,
  },

  -- Auto-close brackets, quotes, etc.
  { "echasnovski/mini.pairs", event = "InsertEnter", opts = {} },

  -- Better a/i text objects (smarter than built-in)
  { "echasnovski/mini.ai", event = { "BufReadPost", "BufNewFile" }, opts = {} },

  -- Surround operations: gsa (add), gsd (delete), gsr (replace), gsf/gsh (find)
  { "echasnovski/mini.surround", event = { "BufReadPost", "BufNewFile" }, opts = {} },
}
