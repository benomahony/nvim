return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  config = function(_, opts)
    require("oil").setup(opts)

    -- Auto-open oil when starting nvim without arguments
    vim.api.nvim_create_autocmd("VimEnter", {
      nested = true,
      callback = function()
        -- Only open oil if we started with no arguments and have an empty buffer
        if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" then
          vim.cmd("Oil")
        end
      end,
    })
  end,
  opts = {
    default_file_explorer = true,
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
