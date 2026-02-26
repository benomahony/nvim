-- Making quitting commands case insensitive because I have fat fingers
for _, cmd in ipairs({ "W", "Wq", "WQ", "Qa", "QA", "Wqa", "WQa", "WQA", "Qwa", "QWa", "QWA" }) do
  vim.api.nvim_create_user_command(cmd, function()
    vim.cmd(cmd:lower())
  end, { desc = "Quitting for fat fingers" })
end
-- Nice oily navigation
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Buffer picker
vim.keymap.set("n", "<leader>bb", function()
  require("snacks").picker.buffers()
end, { noremap = true, silent = true, desc = "Find buffers" })

-- Find files (smart)
vim.keymap.set("n", "<leader><leader>", function()
  require("snacks").picker.smart({ filter = { cwd = true } })
end, { noremap = true, silent = true, desc = "Find files (smart)" })

-- Split line on character
vim.keymap.set("n", "<leader>J", function()
  local char = vim.fn.input("Split on character: ")
  if char ~= "" then
    local escaped = vim.fn.escape(char, "/\\")
    vim.cmd("s/" .. escaped .. "/" .. escaped .. "\\r/g")
  end
end, { desc = "Split line on character" })

vim.keymap.set("v", "<leader>J", function()
  local char = vim.fn.input("Split on character: ")
  if char ~= "" then
    local escaped = vim.fn.escape(char, "/\\")
    vim.cmd("'<,'>s/" .. escaped .. "/" .. escaped .. "\\r/g")
  end
end, { desc = "Split selection on character" })

-- Fix type "#" on terminal (ghostty & wezterm both have this issue)
vim.keymap.set("i", "<M-3>", "#")


vim.keymap.set("n", "<leader>cp", function()
  require("snacks").terminal.toggle("pre-commit run", {
    auto_close = false,
    win = {
      floating = true,
      width = 0.8,
      height = 0.7,
    },
  })
end, { desc = "Run precommit" })

vim.keymap.set("n", "<leader>tt", function()
  require("snacks").terminal.toggle()
end, { desc = "Toggle terminal" })

vim.keymap.del("n", "<leader>:")

vim.keymap.set("n", "yp", function()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    require("snacks").notify("❌ No file path available", { title = "Error", level = "error" })
    return
  end
  if filepath:match("^oil:///") then
    filepath = filepath:gsub("^oil:///", "")
  end
  if filepath:match("^oil://") then
    filepath = filepath:gsub("^oil://", "")
  end
  vim.fn.setreg("+", filepath)
  require("snacks").notify("📋 yanked path: " .. filepath, { title = "Yank Path" })
end, { desc = "Yank Path to clipboard" })

-- Surround list items with quotes
vim.keymap.set("v", "gsw", function()
  -- Replace opening bracket with bracket + quote
  vim.cmd("'<,'>s/\\[/[\"")
  -- Replace closing bracket with quote + bracket
  vim.cmd("'<,'>s/\\]/\"]")
  -- Replace comma-space with quote-comma-quote-space
  vim.cmd("'<,'>s/, /\", \"/g")
end, { desc = "Quote list items" })

-- Add the word under the cursor to a specific Vale vocabulary file.
local function add_word_to_vale_vocab()
  local vocab_file_path =
    "/Users/benomahony/writing/building-ai-agent-platforms/styles/config/vocabularies/Base/accept.txt"
  local word = vim.fn.expand("<cword>")

  if word == "" then
    vim.notify("No word under cursor.", vim.log.levels.WARN)
    return
  end

  local command = string.format("echo '%s' >> %s", word, vim.fn.shellescape(vocab_file_path))
  vim.fn.system(command)

  vim.notify('Appended "' .. word .. '" to vocabulary.')
end

vim.keymap.set("n", "zg", add_word_to_vale_vocab, {
  noremap = true,
  silent = true,
  desc = "Add word to Vale vocabulary",
})

vim.keymap.set("n", "<leader>m", function()
  if vim.bo.buftype ~= "" or vim.bo.filetype == "oil" then
    vim.cmd("enew")
  end
  vim.cmd("compiler precommit")
  vim.cmd("silent make")
  vim.cmd("copen")
end, { desc = "Make (pre-commit)" })

vim.keymap.set({ "n", "v" }, "<leader>cu", function()
  local versions = {
    { label = "3.10+", arg = "--py310-plus" },
    { label = "3.11+", arg = "--py311-plus" },
    { label = "3.12+", arg = "--py312-plus" },
    { label = "3.13+", arg = "--py313-plus" },
    { label = "3.14+", arg = "--py314-plus" },
  }

  vim.ui.select(versions, {
    prompt = "Select Python version:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      require("conform").format({
        formatters = { "pyupgrade" },
        lsp_format = "never",
        async = false,
      })
    end
  end)
end, { desc = "Upgrade Python syntax" })
