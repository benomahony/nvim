return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        severity_sort = true,
        update_in_insert = false,
        float = {
          border = "rounded",
          source = true,
          focusable = false,
        },
      })

      -- Hover diagnostics on CursorHold
      local group = vim.api.nvim_create_augroup("HoverDiagnostics", { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = group,
        callback = function()
          local pos = vim.api.nvim_win_get_cursor(0)
          local line = pos[1] - 1
          local diags = vim.diagnostic.get(0, { lnum = line })
          if #diags == 0 then
            return
          end

          local winid = vim.diagnostic.open_float(nil, {
            focusable = false,
            scope = "cursor",
            max_width = math.floor(vim.o.columns * 0.5),
          })

          if winid and vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_set_option_value("wrap", true, { win = winid })
            vim.api.nvim_set_option_value("linebreak", true, { win = winid })
          end
        end,
      })

      -- gd → go to definition (Neovim 0.11+ uses <C-]> via tagfunc, but gd is muscle memory)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to Definition" })
        end,
      })

      -- GOOGLE_API_KEY check for ai-lsp
      if not vim.env.GOOGLE_API_KEY or vim.trim(vim.env.GOOGLE_API_KEY) == "" then
        vim.notify("[ai-lsp] GOOGLE_API_KEY not found in environment.", vim.log.levels.WARN)
      end

      local lspconfig = require("lspconfig")
      local configs = require("lspconfig.configs")

      -- Python
      lspconfig.basedpyright.setup({})

      -- Custom LSP: NASA
      if not configs.NASA then
        configs.NASA = {
          default_config = {
            cmd = { "uvx", "--from", "nasa-lsp", "nasa", "serve" },
            filetypes = { "python" },
            root_dir = lspconfig.util.root_pattern("pyproject.toml", ".git"),
          },
        }
      end
      lspconfig.NASA.setup({})

      -- Custom LSP: wiley
      if not configs.wiley then
        configs.wiley = {
          default_config = {
            cmd = {
              "uv",
              "run",
              "--directory",
              "/Users/benomahony/thoughtworks/wiley-lsp/",
              "wiley-style",
            },
            filetypes = { "markdown", "tex" },
            root_dir = lspconfig.util.root_pattern(".git"),
          },
        }
      end
      lspconfig.wiley.setup({})

      -- Custom LSP: ai-lsp
      if not configs["ai-lsp"] then
        configs["ai-lsp"] = {
          default_config = {
            cmd = { "uv", "run", "--directory", "/Users/benomahony/Code/open_source/ai-lsp", "ai-lsp", "serve" },
            filetypes = {
              "asciidoc",
              "c",
              "cpp",
              "go",
              "java",
              "javascript",
              "lua",
              "markdown",
              "python",
              "rust",
              "typescript",
            },
            root_dir = lspconfig.util.root_pattern(".git"),
          },
        }
      end
      lspconfig["ai-lsp"].setup({})
    end,
  },
}
