return {
  "stevearc/aerial.nvim",
  opts = {
    autojump = true,
    backends = { "treesitter", "lsp", "markdown", "man", "asciidoc", "latex" },
    close_automatic_events = {
      "unfocus",
      "switch_buffer",
    },
    guides = {
      nested_top = " │ ",
      mid_item = " ├─",
      last_item = " └─",
      whitespace = "   ",
    },
    layout = {
      placement = "window",
      default_direction = "right",
      close_on_select = false,
      max_width = 30,
      min_width = 30,
    },
    ignore = {
      buftypes = {},
    },
    -- icons = tools.ui.kind_icons,
    show_guides = true,
  },
  vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle<cr>", { silent = true }),
}
