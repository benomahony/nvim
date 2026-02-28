return {
  {
    "neovim/nvim-lspconfig",
    ---@param _ any
    ---@param opts table|nil
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}
      opts.servers["*"] = opts.servers["*"] or {}
      opts.servers["*"].keys = opts.servers["*"].keys or {}
      table.insert(opts.servers["*"].keys, { "<leader>cc", false })


      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
        virtual_text = false,
        underline = true,
        severity_sort = true,
        update_in_insert = false,
        float = {
          border = "rounded",
          source = "always",
          focusable = false,
        },
      })

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

      if not vim.env.GOOGLE_API_KEY or vim.trim(vim.env.GOOGLE_API_KEY) == "" then
        vim.notify(
          "[ai-lsp] GOOGLE_API_KEY not found in environment. The server may refuse requests.",
          vim.log.levels.WARN
        )
      end

      opts.servers["NASA"] = {
        cmd = { "uvx", "--from", "nasa-lsp", "nasa", "serve" },
        filetypes = { "python" },
        -- root_dir = { "pyproject.toml" },
      }
      opts.servers["wiley"] = {
        cmd = {
          "uv",
          "run",
          "--directory",
          "/Users/benomahony/thoughtworks/wiley-lsp/",
          "wiley-style",
        },
        filetypes = { "markdown", "tex" },
      }
      opts.servers["ai-lsp"] = {
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
      }
    end,
  },
}
