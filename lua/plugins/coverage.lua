return {
  -- Python Testing Utils - coverage + navigation + test generation
  "nvim-lua/plenary.nvim",
  config = function()
    require("python-test-utils").setup()
  end,
  keys = {
    -- Coverage commands (simplified)
    {
      "<leader>tx",
      function()
        require("python-test-utils").coverage.toggle()
      end,
      desc = "Toggle coverage",
    },
    {
      "<leader>tc",
      function()
        require("python-test-utils").coverage.buffer_summary()
      end,
      desc = "Coverage summary (buffer)",
    },
    {
      "<leader>tC",
      function()
        require("python-test-utils").coverage.project_summary()
      end,
      desc = "Coverage summary (project)",
    },

    -- Navigation + test generation
    {
      "<leader>tg",
      function()
        require("python-test-utils").navigation.go_to_test()
      end,
      desc = "Go to test/source",
    },
    {
      "<leader>tn",
      function()
        require("python-test-utils").generation.generate_test_for_function()
      end,
      desc = "Generate test for function",
    },
    {
      "<leader>tm",
      function()
        require("python-test-utils").generation.generate_test_for_missing()
      end,
      desc = "Generate test for missing coverage",
    },
  },
}
