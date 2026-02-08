-- Load options first (mapleader must be set before lazy.nvim)
require("config.options")
-- Bootstrap lazy.nvim and load plugins
require("config.lazy")
-- Set colorscheme (after plugins are loaded)
vim.cmd.colorscheme("tokyonight")
-- Load keymaps and autocmds (after plugins so they can reference plugin functions)
require("config.keymaps")
require("config.autocmds")
