-- ai-lsp.lua - Add this to your Neovim config

local M = {}

-- Setup AI LSP for semantic analysis (complementary to existing LSPs)
local function setup_ai_lsp()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python", "javascript", "typescript", "rust", "go", "lua", "java", "cpp", "c" },
    callback = function(args)
      local bufnr = args.buf

      -- Only attach if we don't already have ai-lsp attached
      local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "ai-lsp" })
      if #clients > 0 then
        return
      end

      vim.lsp.start({
        name = "ai-lsp",
        cmd = { "uv", "run", "--directory", "/Users/benomahony/Code/open_source/ai-lsp", "ai-lsp" },
        root_dir = vim.fs.root(bufnr, { ".git", "pyproject.toml", "package.json", "Cargo.toml", "go.mod" }),
        settings = {},
        on_attach = function(client, buf)
          -- Only set up AI-specific keymaps, don't override existing LSP bindings
          local opts = { buffer = buf, desc = "AI LSP" }

          -- Manual trigger for AI analysis
          vim.keymap.set("n", "<leader>ai", function()
            -- Force refresh diagnostics by sending didSave
            local params = vim.lsp.util.make_text_document_params(buf)
            vim.lsp.buf_request(buf, "textDocument/didSave", { textDocument = params })
          end, { desc = "Trigger AI Analysis", buffer = buf })

          -- Show only AI diagnostics
          vim.keymap.set("n", "<leader>aI", function()
            local ai_diagnostics = vim.diagnostic.get(buf, { source = "ai-lsp" })
            if #ai_diagnostics > 0 then
              vim.diagnostic.setloclist({ source = "ai-lsp" })
            else
              vim.notify("No AI insights available", vim.log.levels.INFO)
            end
          end, { desc = "Show AI Insights", buffer = buf })

          vim.notify(string.format("🧠 AI LSP attached to %s", vim.api.nvim_buf_get_name(buf)))
        end,
        on_detach = function(client, buf)
          vim.notify("🧠 AI LSP detached")
        end,
      })
    end,
  })
end

-- Customize diagnostic display for AI insights
local function setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = {
      source = "if_many",
      prefix = function(diagnostic)
        if diagnostic.source == "ai-lsp" then
          return "🧠" -- Brain emoji for AI insights
        end
        return "●"
      end,
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.INFO] = "💡", -- Light bulb for AI suggestions
        [vim.diagnostic.severity.HINT] = "💭", -- Thought bubble for hints
      },
    },
    float = {
      source = "always",
      border = "rounded",
      header = function(opts)
        local diag = opts.diagnostic
        if diag and diag.source == "ai-lsp" then
          return { "🧠 AI LSP", "DiagnosticInfo" }
        end
        return { "Diagnostic", "DiagnosticInfo" }
      end,
    },
    severity_sort = true,
  })
end

-- Debug function to check if AI LSP is working
function M.status()
  local clients = vim.lsp.get_clients({ name = "ai-lsp" })
  if #clients > 0 then
    print("🧠 AI LSP is running")
    for _, client in ipairs(clients) do
      print(
        string.format("  - Client ID: %d, attached to %d buffers", client.id, #vim.tbl_keys(client.attached_buffers))
      )
    end
  else
    print("❌ AI LSP not running")
  end

  -- Show log file location
  local log_file = vim.fn.expand("~/.ai-lsp.log")
  if vim.fn.filereadable(log_file) == 1 then
    print(string.format("📝 Logs: %s", log_file))
    -- Show last few log lines
    local lines = vim.fn.readfile(log_file, "", 5)
    for _, line in ipairs(lines) do
      print("  " .. line)
    end
  end
end

-- Test function to manually trigger analysis
function M.test_analysis()
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf, name = "ai-lsp" })

  if #clients == 0 then
    vim.notify("❌ AI LSP not attached to this buffer", vim.log.levels.WARN)
    return
  end

  vim.notify("🧠 Triggering AI LSP...", vim.log.levels.INFO)
  local params = vim.lsp.util.make_text_document_params(buf)
  vim.lsp.buf_request(buf, "textDocument/didSave", { textDocument = params })
end

-- Auto-initialize
setup_ai_lsp()
setup_diagnostics()

-- Commands for debugging
vim.api.nvim_create_user_command("AiLspStatus", M.status, { desc = "Show AI LSP status" })
vim.api.nvim_create_user_command("AiLspTest", M.test_analysis, { desc = "Test AI analysis" })

return M
