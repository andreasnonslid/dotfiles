return {
    "andreasnonslid/justlists",
    -- dev = true,
    -- dir = "~/dev/justlists",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "folke/snacks.nvim",
    },
    config = function()
        local jl = require("justlists")

        -- 1) Initialize with your desired root_dir:
        jl.setup({
            root_dir = vim.fn.expand(
                "/mnt/c/Users/andreas/dropbox/list_directory"
            ),
        })

        -- 2) Keymaps for find / open / quick / delete:

        -- 2a) Find files by name:
        vim.keymap.set("n", "<leader>lf", function()
            jl.find_files()
        end, { desc = "[J]ustLists ▶ Find [F]iles by Name" })

        -- 2b) Find by content:
        vim.keymap.set("n", "<leader>lc", function()
            jl.find_content()
        end, { desc = "[J]ustLists ▶ Find by [C]ontent" })

        -- 2c) Quick-open last file from history:
        vim.keymap.set("n", "<leader>lq", function()
            jl.quick_open()
        end, { desc = "[J]ustLists ▶ [Q]uick Open Last File" })

        -- 2d) Open “todo.md” normally:
        vim.keymap.set("n", "<leader>lt", function()
            jl.open_file("todo.md", "normal")
        end, { desc = "[J]ustLists ▶ Open [T]odo (normal)" })

        -- 2e) Open “todo.md” in a floating window:
        vim.keymap.set("n", "<leader>lT", function()
            jl.open_file("todo.md", "float")
        end, { desc = "[J]ustLists ▶ Open [T]odo (float)" })

        -- 2f) Delete a file under root_dir:
        vim.keymap.set("n", "<leader>ld", function()
            jl.delete_file()
        end, { desc = "[J]ustLists ▶ [D]elete File" })
    end,
}
