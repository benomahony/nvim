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

        -- Configure virtual text for autocompletion
        virtualtext = {
          auto_trigger_ft = { "*" }, -- Enable for all filetypes
          -- Exclude filetypes where you don't want autocompletion
          auto_trigger_ignore_ft = { "TelescopePrompt", "markdown", "text", "help" },
          keymap = {
            -- accept whole completion
            accept = "<Tab>",
            -- accept one line
            accept_line = "<A-a>",
            -- accept n lines (prompts for number)
            accept_n_lines = "<A-z>",
            -- Cycle to prev/next completion item or manually invoke completion
            prev = "<A-[>",
            next = "<A-]>",
            dismiss = "<A-e>",
          },
          -- Whether to show virtual text when completion menu is visible
          show_on_completion_menu = false,
        },

        -- Configure Blink integration
        blink = {
          enable_auto_complete = false, -- We'll focus on virtual text for auto-completion
        },

        -- Ollama configuration with Qwen2.5-coder model
        provider_options = {
          openai_fim_compatible = {
            api_key = "TERM", -- Placeholder since Ollama doesn't need a real API key
            name = "Ollama",
            end_point = "http://localhost:11434/v1/completions",
            model = "qwen2.5-coder", -- Using the 7B parameter model
            stream = true,
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
          },
        },
      })
    end,
  },

  -- Configure Blink
  {
    "Saghen/blink.cmp",
    dependencies = { "milanglacier/minuet-ai.nvim" },
    opts = function()
      -- Make sure Minuet is loaded before requiring it
      local has_minuet, minuet = pcall(require, "minuet")

      local blink_map = nil
      if has_minuet then
        blink_map = minuet.make_blink_map()
      end

      return {
        keymap = {
          -- Manual trigger for minuet completion (only if minuet is available)
          ["<A-y>"] = blink_map,
        },
        completion = {
          trigger = { prefetch_on_insert = false },
        },
        sources = {
          providers = {
            minuet = {
              name = "minuet",
              module = "minuet.blink",
              score_offset = 100, -- Give Minuet higher priority
            },
          },
        },
      }
    end,
  },

  -- Tell LazyVim to use Blink
  {
    "LazyVim/LazyVim",
    opts = {
      -- Set this to choose Blink as the main completion engine
      blink_main = true,
    },
  },
}
