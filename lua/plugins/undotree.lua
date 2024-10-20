return {
  "jiaoshijie/undotree",
  dependencies = "nvim-lua/plenary.nvim",
  config = true,
  position = "right",
  keys = { -- load the plugin only when using it's keybinding:
    { "<leader>U", "<cmd>lua require('undotree').toggle()<cr>" },
  },
}
