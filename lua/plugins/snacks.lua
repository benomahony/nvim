return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  config = function()
    -- First, set up snacks without UV
    local opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      dashboard = {
        preset = {

          ---@type snacks.dashboard.Item[]|fun(items:snacks.dashboard.Item[]):snacks.dashboard.Item[]?
          keys = {
            { icon = ".", key = ".", desc = "Open at root", action = ":Oil" },
            { icon = "🧪", key = "s", desc = "Restore Session", section = "session" },
            { icon = "📁", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "🔍", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "🔙", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "", key = "b", desc = "Browse Github", action = ":lua Snacks.gitbrowse.open()" },
            {
              icon = "",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = "💤 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy },
            { icon = "🚪", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    }
    require("snacks").setup(opts)
  end,
}
