return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  opts = {
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
  },
}
