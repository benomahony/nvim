return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local configs = require("lspconfig.configs")

      -- AI LS
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
          },
          docs = {
            description = "AI-powered Language Server for semantic code analysis",
          },
        }
      end

      -- Vale LSP
      if not configs["vale-ls"] then
        configs["vale-ls"] = {
          default_config = {
            cmd = { "vale-ls" },
            filetypes = { "asciidoc", "markdown", "text", "rst" },
            root_dir = function(fname)
              local util = require("lspconfig.util")
              return util.root_pattern(".vale.ini", ".git")(fname)
            end,
            settings = {},
            name = "vale-ls",
          },
          docs = {
            description = "Vale Language Server for prose linting",
          },
        }
      end

      opts.servers = opts.servers or {}
      opts.servers["ai-lsp"] = {}
      opts.servers["vale-ls"] = {}

      return opts
    end,
  },
}
