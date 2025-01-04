-- Floating Terminal with toggleterm
return {
  "akinsho/toggleterm.nvim",
  config = function()
    local is_windows = vim.loop.os_uname().sysname:match("Windows")

    -- Configure shell based on the platform
    if is_windows then
      vim.o.shell = "cmd.exe" -- Use cmd.exe for Windows
    else
      vim.o.shell = "/bin/bash" -- Use bash for Linux/Mac
    end

    -- Setup toggleterm
    require("toggleterm").setup({
      open_mapping = [[<F4>]],
      direction = "float", -- Floating terminal
      shade_filetypes = {}, -- Filetypes that won't have shading
      hide_numbers = true, -- Hide the line numbers in terminal mode
      insert_mappings = true, -- Use terminal mappings in insert mode
      terminal_mappings = true, -- Use terminal mappings
      start_in_insert = true, -- Start in insert mode
      close_on_exit = true, -- Close terminal when process exits
      float_opts = {
        border = "curved", -- Border style
        width = math.floor(vim.o.columns * 0.8), -- 80% of screen width
        height = math.floor(vim.o.lines * 0.8), -- 80% of screen height
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
      highlights = {
        Normal = { guibg = "Normal" },
        NormalFloat = { link = "Normal" },
        FloatBorder = { guifg = "Normal", guibg = "Normal" },
      },
    })

    -- Custom keymaps
    local Terminal = require("toggleterm.terminal").Terminal
    
    -- Create a lazygit terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "double",
      },
      -- function to run on opening the terminal
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
      end,
      -- function to run on closing the terminal
      on_close = function(term)
        vim.cmd("startinsert!")
      end,
    })
    
    function _lazygit_toggle()
      lazygit:toggle()
    end
    
    -- Keymap for lazygit
    vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})
  end,
} 