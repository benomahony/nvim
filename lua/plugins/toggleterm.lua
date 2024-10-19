return {
  "Akinsho/toggleterm.nvim",
  cmd = "ToggleTerm",
  keys = function(_, keys)
    local mappings = {
      { "n", "<leader>§", ":ToggleTerm<CR>", desc = "Toggle Terminal", { noremap = true, silent = true } },
    }
    return vim.list_extend(mappings, keys)
  end,
  opts = {
    open_mapping = false,
    float_opts = {
      border = "curved",
    },
  },
}
