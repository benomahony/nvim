return {
  "matarina/pyrola.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  build = ":UpdateRemotePlugins",
  config = function(_, opts)
    local pyrola = require("pyrola")
    pyrola.setup({
      kernel_map = { -- Map Jupyter kernel names to Neovim filetypes
        python = "python3",
        r = "ir",
        cpp = "xcpp14",
      },
      split_horizen = false, -- Define the terminal split direction
      split_ratio = 0.3, -- Set the terminal split size
    })

    -- Define key mappings for enhanced functionality
    vim.keymap.set("n", "<Enter>", function()
      pyrola.send_statement_definition()
    end, { noremap = true })

    vim.keymap.set("v", "<leader>vs", function()
      require("pyrola").send_visual_to_repl()
    end, { noremap = true })

    vim.keymap.set("n", "<leader>is", function()
      pyrola.inspect()
    end, { noremap = true })
  end,
}
