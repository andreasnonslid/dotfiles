-- Disable LazyVim default plugins that conflict with your preferences
return {
  -- Disable LazyVim's default telescope since we're using snacks picker
  { "nvim-telescope/telescope.nvim", enabled = false },
  
  -- Disable LazyVim's default neo-tree since we're using oil.nvim
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  
  -- Disable mini.animate completely to prevent any scroll animations
  { "echasnovski/mini.animate", enabled = false },
  
  -- Disable LazyVim's tab functionality and keymaps
  {
    "LazyVim/LazyVim",
    keys = {
      -- Disable all tab-related keymaps
      { "<leader><tab>l", false },      -- Last Tab
      { "<leader><tab>o", false },      -- Close Other Tabs  
      { "<leader><tab>f", false },      -- First Tab
      { "<leader><tab><tab>", false },  -- New Tab
      { "<leader><tab>]", false },      -- Next Tab
      { "<leader><tab>d", false },      -- Close Tab
      { "<leader><tab>[", false },      -- Previous Tab
      { "<leader>uA", false },          -- Toggle Tabline
    },
  },
  
  -- LazyVim includes many other plugins by default. If you find conflicts:
  -- - Check :LazyExtras to see what's enabled  
  -- - Add { "plugin-name", enabled = false } here to disable specific plugins
  -- - Common ones you might want to disable:
  --   { "echasnovski/mini.files", enabled = false },     -- File manager
  --   { "echasnovski/mini.pick", enabled = false },      -- Picker
  --   { "folke/flash.nvim", enabled = false },           -- Motion plugin
  --   { "folke/which-key.nvim", enabled = false },       -- Keymap help
  --   { "numToStr/Comment.nvim", enabled = false },      -- If you prefer mini.comment
  --   { "windwp/nvim-autopairs", enabled = false },      -- If you prefer mini.pairs
  --   { "lukas-reineke/indent-blankline.nvim", enabled = false }, -- If you prefer mini.indentscope
} 