vim.g.lazyvim_python_lsp = "basedpyright"

vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

vim.opt.inccommand = "split"
vim.opt.incsearch = true

vim.g.snack_terminal = "ghostty"

vim.opt_local.colorcolumn = "120"

-- Ensure signcolumn is available for coverage
vim.opt.signcolumn = "yes"

-- Ghostty-specific optimizations
if vim.env.TERM_PROGRAM == "ghostty" or vim.g.snack_terminal == "ghostty" then
  -- Enable true color support (ghostty supports this well)
  vim.opt.termguicolors = true

  -- Better title integration with ghostty
  vim.opt.title = true
  vim.opt.titlestring = "nvim: %f"

  -- Optimize for ghostty's fast rendering
  vim.opt.lazyredraw = false -- ghostty is fast enough
  vim.opt.ttyfast = true
end
