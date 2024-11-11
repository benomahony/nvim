-- TODO: Is this actually any good?
return {
  "syphar/python-docs.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  event = "VeryLazy",
  config = function()
    require("telescope").load_extension("python_docs")
  end,
}
