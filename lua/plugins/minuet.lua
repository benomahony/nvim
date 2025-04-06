return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "Saghen/blink.cmp",
    },
    config = function()
      require("minuet").setup({
        provider = "openai_fim_compatible",
        n_completions = 1, -- recommended for local model to save resources
        context_window = 1024, -- start conservative, increase based on your system's capability
        throttle = 800,
        debounce = 300,
        request_timeout = 2.5,
        notify = "warn",

        virtualtext = {
          auto_trigger_ft = { "lua", "python", "markdown", "rust", "html", "yaml", "toml" },
          auto_trigger_ignore_ft = { "TelescopePrompt", "text", "help" },
          keymap = {
            accept = "<S-Tab>",
            accept_n_lines = "<C-n>",
            dismiss = "<C-e>",
          },
          show_on_completion_menu = false,
        },

        blink = {
          enable_auto_complete = false,
        },

        provider_options = {
          openai_fim_compatible = {
            api_key = "TERM",
            name = "Ollama",
            end_point = "http://localhost:11434/v1/completions",
            model = "qwen2.5-coder",
            stream = true,
            optional = {
              max_tokens = 1024,
              top_p = 0.9,
            },
          },
        },
      })
    end,
  },

  {
    "Saghen/blink.cmp",
    dependencies = { "milanglacier/minuet-ai.nvim" },
    opts = function()
      local has_minuet, minuet = pcall(require, "minuet")

      local blink_map = nil
      if has_minuet then
        blink_map = minuet.make_blink_map()
      end

      return {
        keymap = {
          preset = "enter",
          ["<Tab>"] = { "select_and_accept", "fallback" },
          ["<CR>"] = { "select_and_accept" },
          ["<C-Space>"] = blink_map,
        },
        completion = {
          trigger = { prefetch_on_insert = false },
        },
        sources = {
          providers = {
            minuet = {
              name = "minuet",
              module = "minuet.blink",
              score_offset = 100,
            },
          },
        },
      }
    end,
  },
}
