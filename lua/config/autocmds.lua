-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd("InsertEnter", { pattern = "*", command = "normal! zz" })

-- Reloads the buffer when it's changed externally but only if no changes have been made in vim
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    if not vim.bo.modified then
      vim.cmd.checktime()
    end
  end,
})
