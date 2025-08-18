return {
  {
    "tigion/nvim-asciidoc-preview",
    ft = { "asciidoc" },
    build = "cd server && npm install --omit=dev",
    ---@module 'asciidoc-preview'
    ---@type asciidoc-preview.Config
    opts = {
      -- Add user configuration here
    },
  },
  {
    "lukas-reineke/headlines.nvim",
    ft = { "asciidoc" },
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true,
  },
}
