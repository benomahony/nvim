-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    vim.schedule(function()
      vim.cmd("silent! lua vim.diagnostic.config({ virtual_text = false })")
    end)
  end,
})
require("conform").setup({
  format_on_save = {
    timeout_ms = 400,
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
      end, 100)
    end
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    if not vim.bo.modified then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter" }, {
  pattern = "*",
  callback = function()
    vim.opt.relativenumber = false
  end,
})
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  pattern = "*",
  callback = function()
    vim.opt.relativenumber = true
  end,
})
