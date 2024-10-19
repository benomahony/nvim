return {
  "linux-cultist/venv-selector.nvim",
  dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
  opts = {
    settings = {
      options = {
        notify_user_on_venv_activation = true,
      },
    },
  },
  event = "VeryLazy",
  keys = {
    { "<leader>vs", "<cmd>VenvSelect<cr>" },
  },
}
