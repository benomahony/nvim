return {
  {
    "tigion/nvim-asciidoc-preview",
    ft = { "asciidoc" },
    build = "cd server && npm install --omit=dev",
    opts = {},
  },
  {
    "lukas-reineke/headlines.nvim",
    ft = { "asciidoc" },
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = {},
  },
}
