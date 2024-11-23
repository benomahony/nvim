-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

require("conform").setup({
  format_on_save = {
    timeout_ms = 200,
    lsp_format = "fallback",
  },
})

vim.api.nvim_create_autocmd("InsertEnter", { pattern = "*", command = "normal! zz" })

local autosave_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })
vim.api.nvim_create_autocmd("InsertLeave", {
  group = autosave_group,
  pattern = "*",
  callback = function()
    if vim.bo.modified then
      vim.defer_fn(function()
        vim.cmd("silent! write")
      end, 200)
    end
  end,
})
