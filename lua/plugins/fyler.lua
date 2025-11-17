return {
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-mini/mini.icons" },
  branch = "stable",
  lazy = false,
  opts = {
    views = {
      finder = {
        default_explorer = true,
      },
    },
    watcher = {
      enabled = true,
    },
  },
  config = function(_, opts)
    require("fyler").setup(opts)

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
