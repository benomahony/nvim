return {
  { "rcarriga/nvim-dap-ui", enabled = false },
  {
    "miroshQa/debugmaster.nvim",
    -- osv is needed if you want to debug neovim lua code. Also can be used
    -- as a way to quickly test-drive the plugin without configuring debug adapters
    dependencies = { "mfussenegger/nvim-dap", "jbyuki/one-small-step-for-vimkind", "mason-org/mason.nvim" },
    config = function()
      local dm = require("debugmaster")
      -- make sure you don't have any other keymaps that starts with "<leader>d" to avoid delay
      -- Alternative keybindings to "<leader>d" could be: "<leader>m", "<leader>;"
      vim.keymap.set({ "n", "v" }, "<leader>d", dm.mode.toggle, { nowait = true })
      -- If you want to disable debug mode in addition to leader+d using the Escape key:
      -- vim.keymap.set("n", "<Esc>", dm.mode.disable)
      -- This might be unwanted if you already use Esc for ":noh"
      vim.keymap.set("t", "<C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
      dm.plugins.osv_integration.enabled = true -- needed if you want to debug neovim lua code
      local dap = require("dap")
      -- Configure your debug adapters here
      dap.adapters.python = {
        type = "executable",
        command = "python",
        args = { "-m", "debugpy.adapter" },
        options = {
          source_filetype = "python",
        },
      }
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          console = "integratedTerminal",
        },
      }
      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Debug neovim (lua)",
        },
      }
    end,
  },
}
