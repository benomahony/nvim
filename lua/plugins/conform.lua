return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = { "ruff_fix", "ruff_format" },
      asciidoc = { "asciidoc_format" },
    },
    formatters = {
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
