return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function(_, opts)
      require("oil").setup(opts)
      vim.api.nvim_create_autocmd("VimEnter", {
        nested = true,
        callback = function()
          if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" then
            local ok, p = pcall(require, "persistence")
            local s = ok and p.current()
            if s and vim.fn.filereadable(s) == 1 then
              p.load()
            else
              vim.cmd("Oil")
            end
          end
        end,
      })
    end,
    opts = {
      default_file_explorer = true,
      columns = {
        "icon",
      },
      view_options = {
        show_hidden = false,
      },
    },
  },
  {
    dir = "~/Code/open_source/oil-git.nvim",
    name = "oil-git.nvim",
    dependencies = { "stevearc/oil.nvim" },
  },
}
