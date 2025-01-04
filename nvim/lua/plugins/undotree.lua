-- Undotree - Visual undo history
return {
  "mbbill/undotree",
  config = function()
    -- Configuration options
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_SplitWidth = 40
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_DiffpanelHeight = 10
    vim.g.undotree_DiffAutoOpen = 1
    vim.g.undotree_TreeNodeShape = "●"
    vim.g.undotree_TreeVertShape = "│"
    vim.g.undotree_TreeSplitShape = "╱"
    vim.g.undotree_TreeReturnShape = "╲"
    vim.g.undotree_DiffCommand = "diff"
    vim.g.undotree_RelativeTimestamp = 1
    vim.g.undotree_HighlightChangedText = 1
    vim.g.undotree_HighlightChangedWithSign = 1
    vim.g.undotree_HighlightSyntaxAdd = "DiffAdd"
    vim.g.undotree_HighlightSyntaxChange = "DiffChange"
    vim.g.undotree_HighlightSyntaxDel = "DiffDelete"

    -- Keymap to toggle undotree
    vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<CR>", { desc = "Toggle [U]ndotree" })
  end,
} 