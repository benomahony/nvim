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
  require("telescope").extensions.smart_open.smart_open()
end, { noremap = true, silent = true })

-- Move lines in normal, visual, and insert modes
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==")
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==")
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi")
vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi")
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

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

-- movement
vim.keymap.set({ "n", "v" }, "<C-k>", "<cmd>Treewalker Up<cr>", { silent = true, desc = "Walk tree Up" })
vim.keymap.set({ "n", "v" }, "<C-j>", "<cmd>Treewalker Down<cr>", { silent = true, desc = "Walk tree Down" })
vim.keymap.set({ "n", "v" }, "<C-l>", "<cmd>Treewalker Right<cr>", { silent = true, desc = "Walk tree Right" })
vim.keymap.set({ "n", "v" }, "<C-h>", "<cmd>Treewalker Left<cr>", { silent = true, desc = "Walk tree Left" })

-- swapping
vim.keymap.set("n", "<C-S-j>", "<cmd>Treewalker SwapDown<cr>", { silent = true, desc = "Swap tree Down" })
vim.keymap.set("n", "<C-S-k>", "<cmd>Treewalker SwapUp<cr>", { silent = true, desc = "Swap tree Up" })
vim.keymap.set("n", "<C-S-l>", "<cmd>Treewalker SwapRight<CR>", { silent = true, desc = "Swap tree Right" })
vim.keymap.set("n", "<C-S-h>", "<cmd>Treewalker SwapLeft<CR>", { silent = true, desc = "Swap tree Left" })

-- yank, overwrite and delete whole file
vim.keymap.set("n", "<C-a>", "ggVGy", { noremap = true })
vim.keymap.set("n", "<C-s>", "ggVGp", { noremap = true })
vim.keymap.set("n", "<C-d>", "ggVGD", { noremap = true })

vim.keymap.set("n", "<leader>xu", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("!pyupgrade --py313-plus " .. file)
end, { desc = "Run pyupgrade" })

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

-- Remove LazyVim's <leader>: keymap
vim.keymap.del("n", "<leader>:")
