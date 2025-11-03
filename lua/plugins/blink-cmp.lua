return {
  "saghen/blink.cmp",
  opts = {
    snippets = {
      preset = "luasnip",
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        snippets = {
          score_offset = 10,
        },
      },
    },
  },
}
