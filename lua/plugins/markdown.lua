return {
  "MeanderingProgrammer/render-markdown.nvim",
  enabled = false,
}, {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Recommended
  -- ft = "markdown" -- If you decide to lazy-load anyway

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
}
