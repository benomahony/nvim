return {
  -- "folke/tokyonight.nvim",
  "eldritch-theme/eldritch.nvim",
  opts = {
    -- transparent = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
      comments = { italic = true },
      keywords = { italic = false },
      functions = { italic = false },
      variables = { italic = false },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "eldritch",
    },
  },
}
