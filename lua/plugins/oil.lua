return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    config = function()
      require("oil").setup({
        view_options = {
          show_hidden = true,
        },
      })
    end,
    keys = {
      {
        "-",
        function()
          require("oil").open()
        end,
        desc = "Open parent directory with oil",
      },
    },
    opts = {
      win_options = {
        signcolumn = "yes:2",
        statuscolumn = "",
      },
      view_options = {
        show_hidden = true,
        is_hidden_file = function(name, bufnr)
          return false
        end,
        natural_order = true,
        is_always_hidden = function(name, _)
          return name == ".." or name == ".git"
        end,
      },
    },
    delete_to_trash = true,
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
  },
}
