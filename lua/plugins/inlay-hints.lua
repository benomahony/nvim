return {
  "Davidyz/inlayhint-filler.nvim",
  keys = {
    {
      "<Leader>i",
      function()
        require("inlayhint-filler").fill()
      end,
      desc = "Insert the inlay-hint under cursor into the buffer.",
      mode = { "n", "v" },
    },
    {
      "<Leader>I",
      function()
        vim.cmd("normal! ggVG")
        require("inlayhint-filler").fill()
      end,
      desc = "Insert all inlay-hints in the entire buffer.",
      mode = { "n" },
    },
  },
}
