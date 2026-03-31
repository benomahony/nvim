return {
  "stevearc/aerial.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>a", "<cmd>AerialToggle<cr>", desc = "Aerial (Symbols)" },
  },
  config = function(_, opts)
    require("aerial").setup(opts)
    vim.api.nvim_create_autocmd("CursorMoved", {
      callback = function()
        if vim.bo.filetype == "aerial" then return end
        vim.schedule(function()
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "aerial" then
              vim.api.nvim_win_call(win, function()
                vim.cmd("normal! zz")
              end)
              break
            end
          end
        end)
      end,
    })
  end,
  opts = {
    layout = {
      default_direction = "right",
      placement = "edge",
    },
    show_guides = true,
    highlight_on_hover = true,
    nerd_font = "auto",
  },
}
