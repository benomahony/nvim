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
    lsp_format = "fallback",
  },
  format_on_paste = true,
  formatters_by_ft = {
    python = { "pyupgrade", "ruff_fix" },
  },
  formatters = {
    pyupgrade = {
      command = "pyupgrade",
      prepend_args = { "--py313-plus" },
    },
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
      end, 1200)
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
vim.api.nvim_create_autocmd("User", {
  pattern = "OilActionsPost",
  callback = function(event)
    if event.data.actions.type == "move" then
      Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
    end
  end,
})
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.api.nvim_set_hl(0, "Comment", {
      italic = true,
    })
  end,
})
