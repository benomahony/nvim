return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      show_hidden = true,
      win_options = {
        signcolumn = "yes:2",
        statuscolumn = "",
      },
    },
    delete_to_trash = true,
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
  },
}
