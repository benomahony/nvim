return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local configs = require("lspconfig.configs")

      -- AI LSP
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

      -- Readability LSP
      if not configs["readability-lsp"] then
        configs["readability-lsp"] = {
          default_config = {
            cmd = { "uv", "run", "--directory", "/Users/benomahony/writing/readability-lsp", "readability-lsp" },
            filetypes = { "markdown", "text", "rst", "org", "asciidoc" },
            root_dir = function(fname)
              local util = require("lspconfig.util")
              return util.root_pattern(".git", ".")(fname)
            end,
            settings = {},
          },
          docs = {
            description = "Text readability analysis using textstat",
          },
        }
      end

      opts.servers = opts.servers or {}
      opts.servers["ai-lsp"] = {}
      opts.servers["readability-lsp"] = {}

      return opts
    end,
  },
}
