return {
  "saghen/blink.cmp",
  dependencies = {
    "olimorris/codecompanion.nvim",
  },
  event = "InsertEnter",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    appearance = {
      use_nvim_cmp_as_default = true,
    },
    sources = {
      compat = {},
      default = { "lsp", "path", "snippets", "buffer" },
      per_filetype = {
        codecompanion = { "codecompanion" },
      },
    },
    cmdline = {
      enabled = true,
    },
  },
}
