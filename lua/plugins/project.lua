return {
  "DrKJeff16/project.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("project").setup({
      enable_autochdir = true,
      disable_on = {
        ft = {
          "TelescopePrompt",
          "alpha",
          "lazy",
          "notify",
        },
        bt = { "nofile", "terminal" },
      },
    })
    require("telescope").load_extension("projects")
  end,
}
