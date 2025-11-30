return {
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-mini/mini.icons" },
  branch = "stable",
  lazy = false,
  opts = {
    default_explorer = true,
    watcher = {
      enabled = true,
    },
    win = {
      win_opts = {
        signcolumn = "yes",
        number = true,
      },
    },
  },
  config = function(_, opts)
    require("fyler").setup(opts)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "fyler",
      callback = function()
        vim.opt_local.signcolumn = "yes"
        vim.opt_local.number = true
      end,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
      nested = true,
      callback = function()
        if vim.fn.argc() == 0 then
          require("fyler").open({})
        end
      end,
    })
  end,
}
