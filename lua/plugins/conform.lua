return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = { "pyupgrade", "ruff_fix", "ruff_format" },
    },
    formatters = {
      pyupgrade = {
        command = "pyupgrade",
        args = { "--py313-plus", "-" },
        stdin = true,
        exit_codes = { 0, 1 },
      },
      ruff_fix = {
        exit_codes = { 0, 1 },
      },
    },
  },
}
