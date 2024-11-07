vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>wt", require("wezterm").switch_tab.index)
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
