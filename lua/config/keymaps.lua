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

-- "The greatest remap ever" Paste and delete while retaining what you pasted
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set("n", "<leader>X", "Q !!$SHELL<CR>", { noremap = true })
