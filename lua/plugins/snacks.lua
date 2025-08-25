return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  config = function()
    -- First, set up snacks without UV
    local opts = {
      -- Ghostty-specific terminal optimizations
      terminal = vim.g.snack_terminal == "ghostty" and {
        win = {
          style = "minimal",
          border = "rounded",
          title_pos = "center",
          footer_pos = "center",
        },
        bo = {
          filetype = "snacks_terminal",
          bufhidden = "wipe",
          buftype = "terminal",
        },
        keys = {
          term_normal = {
            q = "close",
            ["<esc>"] = "hide",
            ["<c-z>"] = "hide",
          },
        },
        env = {
          TERM_PROGRAM = "ghostty",
          COLORTERM = "truecolor",
        },
      } or {},
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      explorer = { enabled = false },
      image = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      dashboard = { enabled = false },
      zen_mode = { enabled = false },
      dimming = { enabled = false },
    }
    require("snacks").setup(opts)
  end,
}
