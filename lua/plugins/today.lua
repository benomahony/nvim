local today_file = vim.fn.expand("~/today.md")

local function ensure_file()
  if vim.fn.filereadable(today_file) == 0 then
    vim.fn.writefile({ "# Today", "", "- [ ] " }, today_file)
  end
end

local function edit_today()
  ensure_file()
  vim.cmd("edit " .. today_file)
end

local floating_win = nil
local floating_buf = nil

local function toggle_floating_today()
  ensure_file()

  if floating_win and vim.api.nvim_win_is_valid(floating_win) then
    vim.api.nvim_win_close(floating_win, true)
    floating_win = nil
    return
  end

  local width = 50
  local height = 20
  local ui = vim.api.nvim_list_uis()[1]
  local col = ui.width - width - 2
  local row = 2

  floating_buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(floating_buf, today_file)
  vim.api.nvim_buf_call(floating_buf, function()
    vim.cmd("edit " .. today_file)
  end)

  floating_win = vim.api.nvim_open_win(floating_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " today.md ",
    title_pos = "center",
  })

  vim.api.nvim_set_option_value("wrap", true, { win = floating_win })
  vim.api.nvim_set_option_value("linebreak", true, { win = floating_win })

  vim.keymap.set("n", "q", function()
    vim.cmd("write")
    vim.api.nvim_win_close(floating_win, true)
    floating_win = nil
  end, { buffer = floating_buf, desc = "Close today" })
end

vim.keymap.set("n", "<leader>tD", edit_today, { desc = "Edit today.md" })
vim.keymap.set("n", "<leader>td", toggle_floating_today, { desc = "Today.md floating" })

return {}
