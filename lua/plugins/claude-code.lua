return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local claude_runner = require("claude-runner")
    claude_runner.setup()

    -- Add individual components for up to 9 sessions
    for i = 1, 9 do
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return claude_runner.session_status(i)
        end,
        color = function()
          return claude_runner.session_color(i)
        end,
        cond = function()
          return claude_runner.has_session(i)
        end,
        on_click = function()
          claude_runner.open_session(i)
        end,
      })
    end
  end,
}
