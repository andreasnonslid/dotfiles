return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        event = "VimEnter",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
        },
        opts = { picker = { live_default = true } },
        config = function(_, opts)
            local Snacks = require("snacks")
            Snacks.setup(opts)
            local map, pick = vim.keymap.set, require("snacks.picker")

            local function git_root()
                local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
                if root and root ~= "" then
                    return root
                end
                return vim.loop.cwd()
            end

            -- General
            map("n", "<leader>fh", pick.help, { desc = "[F]ind [H]elp" })
            map("n", "<leader>fk", pick.keymaps, { desc = "[F]ind [K]eymaps" })
            map("n", "<leader>fs", pick.smart, { desc = "[F]ind [S]elect Snacks" })
            map("n", "<leader>fd", pick.diagnostics, { desc = "[F]ind [D]iagnostics" })
            map("n", "<leader>fr", pick.resume, { desc = "[F]ind [R]esume" })
            map("n", "<leader>f.", pick.recent, { desc = "[F]ind Recent Files" })
            map("n", "<leader><leader>", pick.buffers, { desc = "Find buffers" })
            map("n", "<leader>fn", function()
                pick.files({ cwd = vim.fn.stdpath("config") })
            end, { desc = "[F]ind [N]eovim files" })
            map("n", "<leader>/", function()
                pick.buffer({ layout = { width = 0.9, height = 0.7 }, preview = false, winblend = 10 })
            end, { desc = "Search in buffer" })
            map("n", "<leader>ft", "<cmd>TodoSnacks<CR>", { desc = "[F]ind [T]odos" })

            -- Files & Grep (cwd)
            map("n", "<leader>ff", function()
                pick.files({})
            end, { desc = "[F]ind [F]iles (cwd)" })
            map("n", "<leader>fg", function()
                pick.grep({ live = true })
            end, { desc = "[F]ind by [G]rep (cwd)" })
            map("n", "<leader>fw", function()
                pick.grep_word()
            end, { desc = "[F]ind current [W]ord" })

            -- Files & Grep (repo root)
            map("n", "<leader>FF", function()
                pick.files({ cwd = git_root() })
            end, { desc = "[F]ind [F]iles (repo)" })
            map("n", "<leader>FG", function()
                pick.grep({ live = true, cwd = git_root() })
            end, { desc = "[F]ind by [G]rep (repo)" })
            map("n", "<leader>FW", function()
                pick.grep_word({ cwd = git_root() })
            end, { desc = "[F]ind current [W]ord (repo)" })
        end,
    },
}
