-- Making :Q and :W case insensitive because I have fat fingers
vim.api.nvim_create_user_command("Q", "q", { bang = true })
vim.api.nvim_create_user_command("W", "w", { bang = true })
vim.api.nvim_create_user_command("Wq", "wq", { bang = true })
vim.api.nvim_create_user_command("Wqa", "wqa", { bang = true })
-- Nice oily navigation
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
-- Quick file search
vim.keymap.set("n", "<leader><leader>", function()
  require("telescope").extensions.smart_open.smart_open()
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>k", '<cmd>lua require("kubectl").toggle()<cr>', { noremap = true, silent = true })

local function hover_with_window()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.rows * 0.3)

  vim.lsp.handlers["tectDocument/hover"] =
    vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded", max_width = width, max_height = height })
  vim.lsp.buf.hover()
end
vim.keymap.set("n", "K", hover_with_window)

vim.keymap.set("n", "u<leader>X", "Q !!$SHELL<CR>", { noremap = true })


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

