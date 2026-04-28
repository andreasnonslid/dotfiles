return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  opts = {},
  keys = {
    {
      "<leader>sR",
      function()
        require("grug-far").open()
      end,
      mode = "n",
      desc = "Find & Replace (project)",
    },
    {
      "<leader>sR",
      function()
        require("grug-far").with_visual_selection()
      end,
      mode = "v",
      desc = "Find & Replace (selection)",
    },
  },
}
