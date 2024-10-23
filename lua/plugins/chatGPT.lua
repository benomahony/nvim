return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  config = function()
    require("chatgpt").setup({
      -- Run the `op read` command directly from within the shell
      api_key_cmd = "op read op://Employee/OpenAI/apikey",
      openai_params = {
        model = "gpt-4o-latest",
      },
    })
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "folke/trouble.nvim", -- optional
    "nvim-telescope/telescope.nvim",
  },
}
