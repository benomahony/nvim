-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd("InsertEnter", { pattern = "*", command = "normal! zz" })

local autosave_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "BufEnter", "BufWritePre" }, {
  group = autosave_group,
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    local filetype = vim.bo[buf].filetype

    -- Skip special buffer types and Oil
    if buftype ~= "" or filetype == "oil" then
      return
    end

    -- Format using conform
    require("conform").format()

    -- Defer save to ensure formatting completes
    vim.defer_fn(function()
      if vim.bo.modified and vim.bo.buftype == "" and vim.bo.modifiable then
        vim.cmd("silent! write")
      end
    end, 1000)
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
