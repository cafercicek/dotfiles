return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "|" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "_" },
      changedelete = { text = "~" },
    },
  },
  keys = {
    {
      "]h",
      function()
        require("gitsigns").nav_hunk()
      end,
      desc = "Next git hunk",
    },
    {
      "[h",
      function()
        require("gitsigns").nav_hunk({ direction = "prev" })
      end,
      desc = "Prev git hunk",
    },
    {
      "<leader>gp",
      function()
        require("gitsigns").preview_hunk()
      end,
      desc = "Preview hunk",
    },
    {
      "<leader>gu",
      function()
        require("gitsigns").undo_hunk()
      end,
      desc = "Undo hunk",
    },
    {
      "<leader>gS",
      function()
        require("gitsigns").stage_hunk()
      end,
      desc = "Stage hunk",
    },
  },
}
