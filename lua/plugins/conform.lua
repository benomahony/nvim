local function get_python_version_arg()
  local uv = vim.uv or vim.loop
  local cwd = vim.fn.getcwd()
  local pyproject_path = vim.fs.find("pyproject.toml", { path = cwd, upward = true })[1]

  if not pyproject_path then
    return "--py313-plus"
  end

  local file = io.open(pyproject_path, "r")
  if not file then
    return "--py313-plus"
  end

  local content = file:read("*all")
  file:close()

  local requires_python = content:match("requires%-python%s*=%s*[\"']([^\"']+)[\"']")
  if not requires_python then
    return "--py313-plus"
  end

  local min_version = requires_python:match(">=?%s*(%d+%.%d+)")
  if not min_version then
    return "--py313-plus"
  end

  local major, minor = min_version:match("(%d+)%.(%d+)")
  if not major or not minor then
    return "--py313-plus"
  end

  return "--py" .. major .. minor .. "-plus"
end

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
        args = function()
          return { get_python_version_arg(), "-" }
        end,
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
