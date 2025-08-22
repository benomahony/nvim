return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<leader>rs",
        function()
          local clients = vim.lsp.get_clients({ name = "readability-lsp" })
          if #clients == 0 then
            vim.notify("Readability LSP not running", vim.log.levels.WARN)
            return
          end

          -- Request stats via custom LSP method
          local params = { uri = vim.uri_from_bufnr(0) }
          vim.lsp.buf_request(0, "readability/getStats", params, function(err, result)
            if err or not result then
              vim.notify("No readability stats available", vim.log.levels.INFO)
              return
            end

            -- Show stats in a notification
            vim.notify(result.formatted, vim.log.levels.INFO, { title = "📊 Document Statistics" })
          end)
        end,
        desc = "Show readability statistics",
      },
    },
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
            cmd = {
              "uv",
              "run",
              "--directory",
              "/Users/benomahony/Code/open_source/readability-lsp",
              "readability-lsp",
            },
            filetypes = { "markdown", "text", "rst", "org", "asciidoc" },
            root_dir = function(fname)
              local util = require("lspconfig.util")
              return util.root_pattern(".git", "pyproject.toml", "package.json", "Cargo.toml", "go.mod")(fname)
            end,
            settings = {},
          },
          docs = {
            description = "AsciiDoc readability analysis",
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
