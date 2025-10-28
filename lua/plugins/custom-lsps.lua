return {
  {
    "neovim/nvim-lspconfig",
    ---@param _ any
    ---@param opts table|nil
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}

      if not vim.env.GOOGLE_API_KEY or vim.trim(vim.env.GOOGLE_API_KEY) == "" then
        vim.notify(
          "[ai-lsp] GOOGLE_API_KEY not found in environment. The server may refuse requests.",
          vim.log.levels.WARN
        )
      end

      opts.servers["ai-lsp"] = {
        cmd = { "uvx", "ai-lsp" },

        filetypes = { "python", "javascript", "typescript", "rust", "go", "lua", "asciidoc", "java", "cpp", "c" },

        on_new_config = function(root_dir)
          vim.schedule(function()
            vim.notify(("[ai-lsp] starting for %s"):format(root_dir or "(unknown)"), vim.log.levels.DEBUG)
          end)
        end,
      }
    end,
  },
}
