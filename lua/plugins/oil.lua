return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    default_file_explorer = true,
    replace_netrw = true,
    delete_to_trash = true,
    view_options = {
      show_hidden = false,
      natural_order = true,
      is_always_hidden = function(name, _)
        return name == ".." or name == ".git"
      end,
    },
    float = {
      padding = 2,
      max_width = 90,
      max_height = 0,
    },
    win_options = {
      signcolumn = "yes",
      statuscolumn = "",
      wrap = true,
      winblend = 0,
    },
    keymaps = {
      ["<C-c>"] = false,
      ["q"] = "actions.close",
      ["u."] = { "actions.toggle_hidden", desc = "Toggle hidden files and directories" },
    },
  },
}
