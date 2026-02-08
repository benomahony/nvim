-- Essential autocmds (previously provided by LazyVim)

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- Close certain filetypes with q
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("close_with_q", { clear = true }),
  pattern = {
    "help", "man", "notify", "qf", "query", "checkhealth",
    "startuptime", "neotest-output", "neotest-summary", "neotest-output-panel",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Check if file changed outside of vim
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("checktime", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Go to last cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("last_loc", { clear = true }),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
      return
    end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto create parent dirs when saving
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

---------------------------------------------------------------------
-- Custom autocmds (user's original autocmds)
---------------------------------------------------------------------

-- Center cursor on insert
vim.api.nvim_create_autocmd("InsertEnter", { pattern = "*", command = "normal! zz" })

-- Zig build system integration
local group = vim.api.nvim_create_augroup("zig_build_quickfix", { clear = true })

local function setup_zig_make(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return
  end

  local dir = vim.fs.dirname(name)
  local build = vim.fs.find("build.zig", {
    upward = true,
    path = dir,
  })[1]

  if not build then
    return
  end

  local root = vim.fs.dirname(build)

  vim.bo[bufnr].makeprg = "cd " .. vim.fn.fnameescape(root) .. " && zig build"

  vim.bo[bufnr].errorformat = table.concat({
    "%f:%l:%c: %trror: %m",
    "%f:%l:%c: %tarning: %m",
    "%f:%l:%c: note: %m",
    "%-Greferenced here:%m",
  }, ",")
end

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "zig",
  callback = function(args)
    setup_zig_make(args.buf)
  end,
})

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
