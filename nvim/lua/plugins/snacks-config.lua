-- Configure snacks.nvim to disable animations without breaking picker functionality
return {
  {
    "folke/snacks.nvim",
    opts = {
      -- Disable animations but don't touch picker settings
      animate = {
        enabled = false,
      },
      scroll = {
        enabled = false,
      },
      -- Let LazyVim's snacks_picker extra handle all picker configuration
      -- Don't override picker settings here
    },
  },
} 