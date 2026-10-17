return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview file history" },
  },
  config = function()
    require("diffview").setup()
  end,
}
