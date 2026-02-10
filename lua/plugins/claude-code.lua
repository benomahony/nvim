return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local claude = require("claude-runner")
    claude.setup()

    table.insert(opts.sections.lualine_x, 1, {
      claude.status,
      color = claude.status_color,
      on_click = function()
        claude.pick()
      end,
    })
  end,
}
