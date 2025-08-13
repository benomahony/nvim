-- Making :Q and :W case insensitive because I have fat fingers
vim.api.nvim_create_user_command("Q", "q", { bang = true })
vim.api.nvim_create_user_command("W", "w", { bang = true })
vim.api.nvim_create_user_command("Wq", "wq", { bang = true })
vim.api.nvim_create_user_command("Wqa", "wqa", { bang = true })
vim.api.nvim_create_user_command("WQa", "wqa", { bang = true })
vim.api.nvim_create_user_command("WQA", "wqa", { bang = true })
-- Nice oily navigation
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
-- Quick file search
vim.keymap.set("n", "<leader><leader>", function()
  require("snacks").picker.files()
end, { noremap = true, silent = true })

-- Buffer picker
vim.keymap.set("n", "<leader>bb", function()
  require("snacks").picker.buffers()
end, { noremap = true, silent = true, desc = "Find buffers" })

-- Split lines on character
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

-- Function to delete to void and paste
local function delete_void_paste(type)
  if type == "line" then
    vim.cmd('normal! "_ddp')
  else
    vim.cmd([[normal! `[v`]"_dp]])
  end
end

-- Make the function available globally
_G.delete_void_paste = delete_void_paste

-- Set up the operator mapping
vim.keymap.set("n", "m", function()
  vim.o.operatorfunc = "v:lua.delete_void_paste"
  return "g@"
end, { expr = true })

vim.keymap.set("v", "m", '"_dp')
vim.keymap.set("n", "mm", '"_ddp')

-- Fix type "#" on wezterm
vim.keymap.set("i", "<M-3>", "#")

-- Move lines in normal, visual, and insert modes
vim.keymap.set("n", "<M-j>", ":m .+1<CR>==")
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==")
vim.keymap.set("i", "<M-j>", "<Esc>:m .+1<CR>==gi")
vim.keymap.set("i", "<M-k>", "<Esc>:m .-2<CR>==gi")
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv")

-- Traverse with treewalker
vim.keymap.set({ "n", "v" }, "<M-S-k>", "<cmd>Treewalker Up<cr>", { silent = true, desc = "Walk tree Up" })
vim.keymap.set({ "n", "v" }, "<M-S-j>", "<cmd>Treewalker Down<cr>", { silent = true, desc = "Walk tree Down" })
vim.keymap.set({ "n", "v" }, "<M-S-l>", "<cmd>Treewalker Right<cr>", { silent = true, desc = "Walk tree Right" })
vim.keymap.set({ "n", "v" }, "<M-S-h>", "<cmd>Treewalker Left<cr>", { silent = true, desc = "Walk tree Left" })

-- Swap with Treewalker
vim.keymap.set("n", "<D-S-j>", "<cmd>Treewalker SwapDown<cr>", { silent = true, desc = "Swap tree Down" })
vim.keymap.set("n", "<D-S-l>", "<cmd>Treewalker SwapRight<CR>", { silent = true, desc = "Swap tree Right" })
vim.keymap.set("n", "<D-S-h>", "<cmd>Treewalker SwapLeft<CR>", { silent = true, desc = "Swap tree Left" })
vim.keymap.set("n", "<D-S-k>", "<cmd>Treewalker SwapUp<cr>", { silent = true, desc = "Swap tree Up" })

-- yank, overwrite and delete whole file
vim.keymap.set("n", "<C-a>", "ggVGy")

vim.keymap.set("n", "<C-s>", "ggVGp")
vim.keymap.set("n", "<C-d>", "ggVGD")

vim.keymap.set("n", "<leader>xp", function()
  require("snacks").terminal.toggle("pre-commit run", {
    auto_close = false,
    win = {
      floating = true,
      width = 0.8,
      height = 0.7,
    },
  })
end, { desc = "Run precommit" })

-- Go to test/source (moved to <leader>tg)
vim.keymap.set("n", "<leader>tg", function()
  local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")

  if current:match("^tests/") then
    -- Going from test to source
    local source = current:gsub("^tests/", ""):gsub("_test%.py$", ".py")
    if vim.fn.filereadable(source) == 1 then
      vim.cmd("edit " .. source)
      require("snacks").notify("📝 Switched to source: " .. source, { title = "Test → Source" })
    else
      require("snacks").notify("❌ Source file not found: " .. source, { title = "Error", level = "error" })
    end
  else
    -- Going from source to test
    local without_ext = current:gsub("%.py$", "")
    local test_file = "tests/" .. without_ext .. "_test.py"

    if vim.fn.filereadable(test_file) == 1 then
      vim.cmd("edit " .. test_file)
      require("snacks").notify("🧪 Switched to test: " .. test_file, { title = "Source → Test" })
    else
      vim.ui.select({ "Yes", "No" }, {
        prompt = "🆕 Create test file: " .. test_file .. "?",
      }, function(choice)
        if choice == "Yes" then
          vim.fn.mkdir(vim.fn.fnamemodify(test_file, ":h"), "p")
          vim.cmd("edit " .. test_file)
          require("snacks").notify("✨ Created test: " .. test_file, { title = "New Test File" })
        end
      end)
    end
  end
end, { desc = "Go to test/source" })

vim.keymap.del("n", "<leader>:")

-- Copy current buffer path to clipboard
vim.keymap.set("n", "yp", function()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    require("snacks").notify("❌ No file path available", { title = "Error", level = "error" })
    return
  end
  if filepath:match("^oil:///") then
    filepath = filepath:gsub("^oil:///", "")
  end
  vim.fn.setreg("+", filepath)
  require("snacks").notify("📋 yanked path: " .. filepath, { title = "Yank Path" })
end, { desc = "Yank Path to clipboard" })
