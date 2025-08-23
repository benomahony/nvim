return {
  "dmtrKovalenko/fff.nvim",
  build = "cargo build --release",
  opts = {},
  keys = {
    {
      "ff",
      function()
        require("fff").find_files()
      end,
      desc = "Open file picker",
    },
    {
      "<leader><leader>",
      function()
        require("fff").find_files()
      end,
      desc = "Open file picker",
    },
  },
}
