vim.g.lazyvim_python_lsp = "basedpyright"

vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

vim.opt.inccommand = "split"
vim.opt.incsearch = true

vim.g.snack_terminal = "kitty"

vim.diagnostic.config({ virtual_text = false })

-- Ensure our config persists after LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    -- Small delay to ensure this runs after the LSP's own config
    vim.schedule(function()
      vim.diagnostic.config({ virtual_text = false })
    end)
  end,
})
