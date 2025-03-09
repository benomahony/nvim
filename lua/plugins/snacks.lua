return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  config = function()
    -- First, set up snacks without UV
    local opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      dashboard = {
        preset = {
          ---@type snacks.dashboard.Item[]|fun(items:snacks.dashboard.Item[]):snacks.dashboard.Item[]?
          keys = {
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "󰏗", key = "p", desc = "Select Project", action = ":Telescope projects" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          {
            pane = 2,
            section = "terminal",
            cmd = "colorscript -e square",
            height = 5,
            padding = 1,
          },
          { section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          {
            pane = 2,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = vim.fn.isdirectory(".git") == 1,
            cmd = "hub status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          { section = "startup" },
        },
      },
    }

    -- Initialize Snacks with our configuration
    require("snacks").setup(opts)

    -- Now that Snacks is loaded, add UV functionality
    local function run_command(cmd)
      -- Run command in background and capture output
      vim.fn.jobstart(cmd, {
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            vim.notify("Command completed successfully: " .. cmd, vim.log.levels.INFO)
          else
            vim.notify("Command failed: " .. cmd, vim.log.levels.ERROR)
          end
        end,
        on_stdout = function(_, data)
          if data and #data > 1 then
            -- Only show meaningful output (not empty lines)
            local output = table.concat(data, "\n")
            if output and output:match("%S") then
              vim.notify(output, vim.log.levels.INFO)
            end
          end
        end,
        on_stderr = function(_, data)
          if data and #data > 1 then
            -- Show errors
            local output = table.concat(data, "\n")
            if output and output:match("%S") then
              vim.notify(output, vim.log.levels.WARN)
            end
          end
        end,
        stdout_buffered = true,
        stderr_buffered = true,
      })
    end

    -- Activate a virtual environment
    local function activate_venv(venv_path)
      -- For Mac, run the source command to apply to the current shell
      local command = "source " .. venv_path .. "/bin/activate"

      -- Set environment variables for the current Neovim instance
      vim.env.VIRTUAL_ENV = venv_path
      vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH

      -- Notify user
      vim.notify("Activated virtual environment: " .. venv_path, vim.log.levels.INFO)
    end

    -- Auto-activate the .venv if it exists at the project root
    local function auto_activate_venv()
      local venv_path = vim.fn.getcwd() .. "/.venv"
      if vim.fn.isdirectory(venv_path) == 1 then
        activate_venv(venv_path)
        return true
      end
      return false
    end

    -- Set up UV commands
    vim.api.nvim_create_user_command("UVinit", function()
      run_command("uv init")
    end, {})

    -- Auto-activate .venv if it exists
    auto_activate_venv()

    -- Also set up auto-command to check when entering a directory
    vim.api.nvim_create_autocmd({ "DirChanged" }, {
      pattern = { "global" },
      callback = function()
        auto_activate_venv()
      end,
    })

    -- Register UV command source
    Snacks.picker.sources.uv_commands = {
      finder = function()
        return {
          { text = "uv run [current_file]", desc = "Run current file with Python", is_run_current = true },
          { text = "uv add [package]", desc = "Install a package" },
          { text = "uv sync", desc = "Sync packages from lockfile" },
          { text = "uv remove [package]", desc = "Remove a package" },
          { text = "uv init", desc = "Initialize a new project" },
        }
      end,
      format = function(item)
        return { { item.text .. " - " .. item.desc } }
      end,
      confirm = function(picker, item)
        if item then
          picker:close()

          if item.is_run_current then
            -- Special handling for running the current file
            local current_file = vim.fn.expand("%:p")
            if current_file and current_file ~= "" then
              vim.notify("Running: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)

              -- Run python on the current file and capture output to notifications
              vim.fn.jobstart("uv run python " .. vim.fn.shellescape(current_file), {
                on_stdout = function(_, data)
                  if data and #data > 1 then
                    local output = table.concat(data, "\n")
                    if output and output:match("%S") then
                      vim.notify(output, vim.log.levels.INFO, {
                        title = "Python Output",
                        timeout = 10000,
                      })
                    end
                  end
                end,
                on_stderr = function(_, data)
                  if data and #data > 1 then
                    local output = table.concat(data, "\n")
                    if output and output:match("%S") then
                      vim.notify(output, vim.log.levels.ERROR, {
                        title = "Python Error",
                        timeout = 10000,
                      })
                    end
                  end
                end,
                on_exit = function(_, exit_code)
                  if exit_code == 0 then
                    vim.notify("Program execution completed successfully", vim.log.levels.INFO, {
                      title = "Python Execution",
                    })
                  else
                    vim.notify("Program execution failed with exit code: " .. exit_code, vim.log.levels.ERROR, {
                      title = "Python Execution",
                    })
                  end
                end,
                stdout_buffered = true,
                stderr_buffered = true,
              })
            else
              vim.notify("No file is open", vim.log.levels.WARN)
            end
            return
          end

          local cmd = item.text
          -- Check if command needs input
          if cmd:match("%[(.-)%]") then
            local param_name = cmd:match("%[(.-)%]")

            vim.ui.input({ prompt = "Enter " .. param_name .. ": " }, function(input)
              if not input or input == "" then
                vim.notify("Cancelled", vim.log.levels.INFO)
                return
              end

              -- Replace the placeholder with actual input
              local actual_cmd = cmd:gsub("%[" .. param_name .. "%]", input)
              run_command(actual_cmd)
            end)
          else
            -- Run the command directly
            run_command(cmd)
          end
        end
      end,
    }

    -- Register UV venv source
    Snacks.picker.sources.uv_venv = {
      finder = function()
        local venvs = {}

        -- Check for .venv directory (uv's default)
        if vim.fn.isdirectory(".venv") == 1 then
          table.insert(venvs, {
            text = ".venv",
            path = vim.fn.getcwd() .. "/.venv",
            is_current = vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV:match(".venv$") ~= nil,
          })
        end

        if #venvs == 0 then
          table.insert(venvs, {
            text = "Create new virtual environment (uv venv)",
            is_create = true,
          })
        end

        return venvs
      end,
      format = function(item)
        if item.is_create then
          return { { "+ " .. item.text } }
        else
          local icon = item.is_current and "● " or "○ "
          return { { icon .. item.text .. " (Activate)" } }
        end
      end,
      confirm = function(picker, item)
        picker:close()
        if item then
          if item.is_create then
            run_command("uv venv")
          else
            activate_venv(item.path)
          end
        end
      end,
    }

    -- Add keybindings for UV commands
    vim.api.nvim_set_keymap(
      "n",
      "<leader>uv",
      "<cmd>lua Snacks.picker.pick('uv_commands')<CR>",
      { noremap = true, silent = true }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>ue",
      "<cmd>lua Snacks.picker.pick('uv_venv')<CR>",
      { noremap = true, silent = true }
    )

    vim.api.nvim_set_keymap("n", "<leader>ui", "<cmd>UVinit<CR>", { noremap = true, silent = true })
  end,
}
