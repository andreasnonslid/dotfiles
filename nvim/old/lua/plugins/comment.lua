return {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("Comment").setup({
            mappings = {
                basic = true,
                extra = false, -- Disable extra mappings like 'gco', 'gcO', 'gcA'
            },
        })
    end,
}
