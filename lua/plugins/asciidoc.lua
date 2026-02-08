return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
          require("nvim-treesitter.parsers").asciidoc = {
            install_info = {
              url = "https://github.com/cathaysia/tree-sitter-asciidoc",
              location = "tree-sitter-asciidoc",
              files = { "src/parser.c", "src/scanner.c" },
              branch = "master",
            },
          }
        end,
      })
    end,
  },
  {
    "benomahony/render-asciidoc.nvim",
    dir = "/Users/benomahony/Code/open_source/asciidoc-render.nvim",
    ft = "asciidoc",
    opts = {},
  },
}
