return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = { "pyupgrade", "ruff_fix", "ruff_format" },
      asciidoc = { "asciidoc_format" },
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
      asciidoc_format = {
        command = "/Users/benomahony/writing/building-ai-agent-platforms/tools/asciidoc-format",
        stdin = true,
        exit_codes = { 0, 1 },
      },
    },
  },
}
