return {
  "ramilito/kubectl.nvim",
  config = function()
    require("kubectl").setup({
      log_level = vim.log.levels.INFO,
      logs = {
        prefix = true,
        timestamps = true,
        since = "5m",
      },
      namespace = "All",
      namespace_fallback = {},
      dff = {
        bin = "kubediff",
      },
      auto_refresh = {
        enabled = true,
        interval = 200, -- milliseconds
      },
      lineage = {
        enabled = true,
      },
      hints = true,
      obj_fresh = 10,
      context = true,
      float_size = {
        width = 0.9,
        height = 0.8,
      },
      headers = true,
      heartbeat = true,
      kubernetes_versions = true,
    })
  end,
}
