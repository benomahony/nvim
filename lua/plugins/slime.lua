return {
  {
    "jpalardy/vim-slime",
    init = function()
      vim.g.slime_target = "neovim"
    end,
    config = function()
      vim.keymap.set({ "n", "i" }, "<m-cr>", function()
        vim.cmd([[ call slime#send_cell() ]])
      end, { desc = "Send cell to terminal" })
    end,
  },
}
