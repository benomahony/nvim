-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("dap-python").setup("uv")

vim.g.lazygit_executable = "/Users/benomahony/Code/open_source/lazygit/lazygit"
