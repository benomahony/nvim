return {
  "supermaven-inc/supermaven-nvim",
  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
      },
      color = {
        -- suggestion_color = "#bb9af7",
        -- suggestion_color = "#7aa2f7",
        suggestion_color = "#414868",
        -- suggestion_color = "#565f89",
        cterm = 244,
      },
    })
  end,
}
