-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd("InsertEnter", { pattern = "*", command = "normal! zz" })

local group = vim.api.nvim_create_augroup("zig_build_quickfix", { clear = true })

local function setup_zig_make(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return
  end

  -- Find nearest build.zig upwards from the file’s directory
  local dir = vim.fs.dirname(name)
  local build = vim.fs.find("build.zig", {
    upward = true,
    path = dir,
  })[1]

  -- If there is no build.zig, do nothing (no :make on save)
  if not build then
    return
  end

  local root = vim.fs.dirname(build)

  -- Always run `zig build` from the project root
  vim.bo[bufnr].makeprg = "cd " .. vim.fn.fnameescape(root) .. " && zig build"

  -- Parse Zig-style diagnostics into quickfix
  vim.bo[bufnr].errorformat = table.concat({
    "%f:%l:%c: %trror: %m", -- foo.zig:12:34: error: message
    "%f:%l:%c: %tarning: %m", -- foo.zig:12:34: warning: message
    "%-G%.%#", -- ignore the rest
  }, ",")
end

-- Configure makeprg/errorformat for all Zig buffers
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "zig",
  callback = function(args)
    setup_zig_make(args.buf)
  end,
})

-- Run :make! on every Zig save (only if makeprg was set above)
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.zig",
  callback = function()
    if vim.bo.makeprg == "" or not vim.bo.makeprg:match("zig build") then
      return
    end
    vim.cmd("silent make! | silent redraw!")
  end,
})

-- After :make, open quickfix if there are any entries, else close it
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  group = group,
  pattern = "make",
  callback = function()
    if #vim.fn.getqflist() > 0 then
      vim.cmd("cwindow")
    else
      vim.cmd("cclose")
    end
  end,
})
