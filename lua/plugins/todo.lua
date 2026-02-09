local today_file = vim.fn.expand("~/todo.md")

-- Configuration: set to true to open today.md on launch
local open_on_launch = true

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

  floating_buf = vim.fn.bufadd(today_file)
  vim.fn.bufload(floating_buf)

  -- Explicitly set filetype for syntax highlighting
  vim.bo[floating_buf].filetype = "markdown"

  -- Second parameter: false = don't enter window, true = enter window
  local should_enter = vim.fn.argc() ~= 0  -- Only enter if not on launch
  floating_win = vim.api.nvim_open_win(floating_buf, should_enter, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Todo",
    title_pos = "center",
  })

  vim.api.nvim_set_option_value("wrap", true, { win = floating_win })
  vim.api.nvim_set_option_value("linebreak", true, { win = floating_win })

  vim.keymap.set("n", "q", function()
    vim.cmd("write")
    vim.api.nvim_win_close(floating_win, true)
    floating_win = nil
  end, { buffer = floating_buf, desc = "Close today" })

  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local new_line
    if line:match("%[%s%]") then
      new_line = line:gsub("%[%s%]", "[x]", 1)
    elseif line:match("%[x%]") then
      new_line = line:gsub("%[x%]", "[ ]", 1)
    else
      return
    end
    vim.api.nvim_set_current_line(new_line)
  end, { buffer = floating_buf, desc = "Toggle todo" })
end

vim.keymap.set("n", "<leader>td", toggle_floating_today, { desc = "Today.md floating" })
vim.keymap.set("n", "<leader>tD", edit_today, { desc = "Edit today.md" })

if open_on_launch then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if vim.fn.argc() == 0 then
        toggle_floating_today()
      end
    end,
  })
end

return {}
