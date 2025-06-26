return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
  },
  {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "saghen/blink.cmp",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      experimental = {
        check_rtp = false,
      },
    },
  },
}
