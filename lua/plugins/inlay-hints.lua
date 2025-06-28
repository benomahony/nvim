return {
  "Davidyz/inlayhint-filler.nvim",
  keys = {
    {
      "<Leader>i",
      function()
        require("inlayhint-filler").fill()
      end,
      desc = "Insert the inlay-hint under cursor into the buffer.",
      mode = { "n", "v" }, -- include 'v' if you want to use it in visual selection mode
    },
    {
      "<Leader>I",
      function()
        vim.cmd("normal! ggVG") -- Visually select the entire buffer
        require("inlayhint-filler").fill()
      end,
      desc = "Insert all inlay-hints in the entire buffer.",
      mode = { "n" }, -- Only allow from normal mode, as we're doing the selection
    },
  },
}
