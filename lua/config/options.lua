vim.g.lazyvim_python_lsp = "basedpyright"

vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10
vim.opt.inccommand = "split"
vim.opt.incsearch = true
vim.opt.signcolumn = "yes"
vim.opt.swapfile = false
vim.opt_global.spelling = true
if vim.bo.filetype("asciidoc") then
  vim.opt_local.wrap = true
end
vim.g.snack_terminal = "ghostty"
