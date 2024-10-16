return {
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-python", "nvim-treesitter/nvim-treesitter" },
    opts = function(_, opts)
      table.insert(
        opts.adapters,
        require("neotest-python")({
          runner = "pytest",
        })
      )
    end,
  },
}
