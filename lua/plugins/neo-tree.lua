return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    {
      "\\",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
      end,
      desc = "Explorer NeoTree (Root Dir)",
    },
  },
  opts = {
    window = {
      position = "right",
      mappings = {
        ["Y"] = "none",
      },
    },
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_by_name = {
          ".git",
        },
        always_show = {
          ".env",
        },
      },
    },
  },
}
