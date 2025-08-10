return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local configs = require("lspconfig.configs")

      if not configs["ai-lsp"] then
        configs["ai-lsp"] = {
          default_config = {
            cmd = { "uv", "run", "--directory", "/Users/benomahony/Code/open_source/ai-lsp", "ai-lsp" },
            filetypes = { "python", "javascript", "typescript", "rust", "go", "lua", "java", "cpp", "c" },
            root_dir = function(fname)
              local util = require("lspconfig.util")
              return util.root_pattern(".git", "pyproject.toml", "package.json", "Cargo.toml", "go.mod")(fname)
            end,
            settings = {},
            name = "ai-lsp",
          },
          docs = {
            description = "AI-powered Language Server for semantic code analysis",
          },
        }
      end

      opts.servers = opts.servers or {}
      opts.servers["ai-lsp"] = {}

      return opts
    end,
  },
}
