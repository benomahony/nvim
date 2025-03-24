return {
  "atiladefreitas/dooing",
  config = function()
    require("dooing").setup({})
  end,
  keys = {
    { "<leader>T", "<cmd>Dooing<cr>", desc = "Open ToDos" },
  },
}
