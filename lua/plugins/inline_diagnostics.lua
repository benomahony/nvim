return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  config = function()
    require("tiny-inline-diagnostic").setup({
      preset = "amongus",
      options = {
        softwrap = 40,
        multilines = {
          enabled = true,
        },
        overflow = {
          mode = "wrap",
          padding = 5,
        },
      },
    })
  end,
}
