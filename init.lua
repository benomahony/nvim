-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.pydanticai_mcp_conversion")
require("dap-python").setup("uv")
