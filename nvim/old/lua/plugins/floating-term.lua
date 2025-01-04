return {
    {
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
                },
            })
        end,
        cmd = "ToggleTerm",
        keys = {
            {
                "<F4>",
                "<cmd>ToggleTerm<cr>",
                desc = "Toggle floating terminal",
            },
        },
    },
}
