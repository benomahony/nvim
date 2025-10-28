return {
  {
    "tigion/nvim-asciidoc-preview",
    ft = { "asciidoc" },
    build = "cd server && npm install --omit=dev",
    ---@module 'asciidoc-preview'
    ---@type asciidoc-preview.Config
    opts = {},
    config = function(_, opts)
      require("asciidoc-preview").setup(opts)
    end,
  },
  {
    "lukas-reineke/headlines.nvim",
    ft = { "asciidoc" },
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true,
  },
}
