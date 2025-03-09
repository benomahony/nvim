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
    require("snacks").setup(opts)

    _G.run_command = function(cmd)
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
            local output = table.concat(data, "\n")
            if output and output:match("%S") then
              vim.notify(output, vim.log.levels.INFO)
            end
          end
        end,
        on_stderr = function(_, data)
          if data and #data > 1 then
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

    local function activate_venv(venv_path)
      local command = "source " .. venv_path .. "/bin/activate"
      vim.env.VIRTUAL_ENV = venv_path
      vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
      vim.notify("Activated virtual environment: " .. venv_path, vim.log.levels.INFO)
    end

    local function auto_activate_venv()
      local venv_path = vim.fn.getcwd() .. "/.venv"
      if vim.fn.isdirectory(venv_path) == 1 then
        activate_venv(venv_path)
        return true
      end
      return false
    end

    local function run_python_selection()
      local get_visual_selection = function()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.fn.getline(start_pos[2], end_pos[2])

        if #lines == 0 then
          return ""
        end

        if #lines > 0 then
          lines[#lines] = lines[#lines]:sub(1, end_pos[3])
        end

        if #lines > 0 then
          lines[1] = lines[1]:sub(start_pos[3])
        end

        return table.concat(lines, "\n")
      end

      local get_buffer_globals = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local imports = {}
        local globals = {}
        local in_class = false
        local class_indent = 0

        for _, line in ipairs(lines) do
          if line:match("^%s*import ") or line:match("^%s*from .+ import") then
            table.insert(imports, line)
          end

          if line:match("^%s*class ") then
            in_class = true
            class_indent = line:match("^(%s*)"):len()
          end

          if in_class and line:match("^%s*[^%s#]") then
            local current_indent = line:match("^(%s*)"):len()
            if current_indent <= class_indent then
              in_class = false
            end
          end

          if not in_class and not line:match("^%s*def ") and line:match("^%s*[%w_]+ *=") then
            if not line:match("^%s%s+") then
              table.insert(globals, line)
            end
          end
        end

        return imports, globals
      end

      local selection = get_visual_selection()
      if selection == "" then
        vim.notify("No code selected", vim.log.levels.WARN)
        return
      end

      local imports, globals = get_buffer_globals()

      local temp_dir = vim.fn.expand("$HOME") .. "/.cache/nvim/uv_run"
      vim.fn.mkdir(temp_dir, "p")
      local temp_file = temp_dir .. "/run_selection.py"
      local file = io.open(temp_file, "w")
      if not file then
        vim.notify("Failed to create temporary file", vim.log.levels.ERROR)
        return
      end

      for _, imp in ipairs(imports) do
        file:write(imp .. "\n")
      end
      file:write("\n")

      for _, glob in ipairs(globals) do
        file:write(glob .. "\n")
      end
      file:write("\n")

      file:write("# SELECTED CODE\n")

      local is_all_indented = true
      for line in selection:gmatch("[^\r\n]+") do
        if not line:match("^%s+") and line ~= "" then
          is_all_indented = false
          break
        end
      end

      local is_function_def = selection:match("^%s*def%s+[%w_]+%s*%(")
      local is_class_def = selection:match("^%s*class%s+[%w_]+")
      local has_print = selection:match("print%s*%(")
      local is_expression = not is_function_def
        and not is_class_def
        and not selection:match("=")
        and not selection:match("%s*for%s+")
        and not selection:match("%s*if%s+")
        and not has_print

      if is_all_indented then
        file:write("def run_selection():\n")
        for line in selection:gmatch("[^\r\n]+") do
          file:write("    " .. line .. "\n")
        end
        file:write("\n# Auto-call the wrapper function\n")
        file:write("run_selection()\n")
      else
        file:write(selection .. "\n")

        if is_expression then
          file:write("\n# Auto-added print for expression\n")
          file:write('print(f"Expression result: {' .. selection:gsub("^%s+", ""):gsub("%s+$", "") .. '}")\n')
        elseif is_function_def then
          local function_name = selection:match("def%s+([%w_]+)%s*%(")
          if function_name and not selection:match(function_name .. "%s*%(.-%)") then
            file:write("\n# Auto-added function call\n")
            file:write('if __name__ == "__main__":\n')
            file:write('    print(f"Auto-executing function: ' .. function_name .. '")\n')
            file:write("    result = " .. function_name .. "()\n")
            file:write("    if result is not None:\n")
            file:write('        print(f"Return value: {result}")\n')
          end
        elseif not has_print and not selection:match("^%s*#") then
          file:write("\n# Auto-added execution marker\n")
          file:write('print("Code executed successfully.")\n')
        end
      end

      file:close()

      vim.notify("Running selected code...", vim.log.levels.INFO)
      vim.fn.jobstart("uv run python " .. vim.fn.shellescape(temp_file), {
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
            vim.notify("Selected code executed successfully", vim.log.levels.INFO)
          else
            vim.notify("Selected code execution failed with exit code: " .. exit_code, vim.log.levels.ERROR)
          end
        end,
        stdout_buffered = true,
        stderr_buffered = true,
      })
    end

    local function run_python_function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local buffer_content = table.concat(lines, "\n")

      local functions = {}
      for line in buffer_content:gmatch("[^\r\n]+") do
        local func_name = line:match("^def%s+([%w_]+)%s*%(")
        if func_name then
          table.insert(functions, func_name)
        end
      end

      if #functions == 0 then
        vim.notify("No functions found in current file", vim.log.levels.WARN)
        return
      end

      local run_function = function(func_name)
        local temp_dir = vim.fn.expand("$HOME") .. "/.cache/nvim/uv_run"
        vim.fn.mkdir(temp_dir, "p")
        local temp_file = temp_dir .. "/run_function.py"
        local current_file = vim.fn.expand("%:p")

        local file = io.open(temp_file, "w")
        if not file then
          vim.notify("Failed to create temporary file", vim.log.levels.ERROR)
          return
        end

        local module_name = vim.fn.fnamemodify(current_file, ":t:r")
        local module_dir = vim.fn.fnamemodify(current_file, ":h")

        file:write("import sys\n")
        file:write("sys.path.insert(0, " .. vim.inspect(module_dir) .. ")\n")
        file:write("import " .. module_name .. "\n\n")
        file:write('if __name__ == "__main__":\n')
        file:write('    print(f"Running function: ' .. func_name .. '")\n')
        file:write("    result = " .. module_name .. "." .. func_name .. "()\n")
        file:write("    if result is not None:\n")
        file:write('        print(f"Return value: {result}")\n')
        file:close()

        vim.notify("Running function: " .. func_name, vim.log.levels.INFO)
        vim.fn.jobstart("uv run python " .. vim.fn.shellescape(temp_file), {
          on_stdout = function(_, data)
            if data and #data > 1 then
              local output = table.concat(data, "\n")
              if output and output:match("%S") then
                vim.notify(output, vim.log.levels.INFO, {
                  title = "Function Output",
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
                  title = "Function Error",
                  timeout = 10000,
                })
              end
            end
          end,
          on_exit = function(_, exit_code)
            if exit_code == 0 then
              vim.notify("Function executed successfully", vim.log.levels.INFO)
            else
              vim.notify("Function execution failed with exit code: " .. exit_code, vim.log.levels.ERROR)
            end
          end,
          stdout_buffered = true,
          stderr_buffered = true,
        })
      end

      if #functions == 1 then
        run_function(functions[1])
        return
      end

      vim.ui.select(functions, {
        prompt = "Select function to run:",
        format_item = function(item)
          return "def " .. item .. "()"
        end,
      }, function(choice)
        if choice then
          run_function(choice)
        end
      end)
    end

    vim.api.nvim_create_user_command("UVinit", function()
      run_command("uv init")
    end, {})

    vim.api.nvim_create_user_command("UVrunSelection", function()
      run_python_selection()
    end, { range = true })

    vim.api.nvim_create_user_command("UVrunFunction", function()
      run_python_function()
    end, {})

    auto_activate_venv()

    vim.api.nvim_create_autocmd({ "DirChanged" }, {
      pattern = { "global" },
      callback = function()
        auto_activate_venv()
      end,
    })

    Snacks.picker.sources.uv_commands = {
      finder = function()
        return {
          { text = "Run current file", desc = "Run current file with Python", is_run_current = true },
          { text = "Run selection", desc = "Run selected Python code", is_run_selection = true },
          { text = "Run function", desc = "Run specific Python function", is_run_function = true },
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
            local current_file = vim.fn.expand("%:p")
            if current_file and current_file ~= "" then
              vim.notify("Running: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
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
          elseif item.is_run_selection then
            local mode = vim.fn.mode()

            if mode == "v" or mode == "V" or mode == "" then
              vim.cmd("normal! \27")
              vim.defer_fn(function()
                run_python_selection()
              end, 100)
            else
              vim.notify("Please select text first. Enter visual mode (v) and select code to run.", vim.log.levels.INFO)
              vim.api.nvim_create_autocmd("ModeChanged", {
                pattern = "[vV\x16]*:n",
                callback = function(ev)
                  run_python_selection()
                  return true
                end,
                once = true,
              })
            end
            return
          elseif item.is_run_function then
            run_python_function()
            return
          end

          local cmd = item.text
          if cmd:match("%[(.-)%]") then
            local param_name = cmd:match("%[(.-)%]")
            vim.ui.input({ prompt = "Enter " .. param_name .. ": " }, function(input)
              if not input or input == "" then
                vim.notify("Cancelled", vim.log.levels.INFO)
                return
              end
              local actual_cmd = cmd:gsub("%[" .. param_name .. "%]", input)
              run_command(actual_cmd)
            end)
          else
            run_command(cmd)
          end
        end
      end,
    }

    Snacks.picker.sources.uv_venv = {
      finder = function()
        local venvs = {}
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

    vim.api.nvim_set_keymap(
      "n",
      "<leader>x",
      "<cmd>lua Snacks.picker.pick('uv_commands')<CR>",
      { noremap = true, silent = true, desc = "UV Commands" }
    )
    vim.api.nvim_set_keymap(
      "v",
      "<leader>x",
      ":<C-u>lua Snacks.picker.pick('uv_commands')<CR>",
      { noremap = true, silent = true, desc = "UV Commands" }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>xr",
      "<cmd>lua Snacks.picker.sources.uv_commands.confirm(nil, {is_run_current = true})<CR>",
      { noremap = true, silent = true, desc = "UV Run Current File" }
    )

    vim.api.nvim_set_keymap(
      "v",
      "<leader>xs",
      ":<C-u>UVrunSelection<CR>",
      { noremap = true, silent = true, desc = "UV Run Selection" }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>xf",
      "<cmd>UVrunFunction<CR>",
      { noremap = true, silent = true, desc = "UV Run Function" }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>xe",
      "<cmd>lua Snacks.picker.pick('uv_venv')<CR>",
      { noremap = true, silent = true, desc = "UV Environment" }
    )

    vim.api.nvim_set_keymap("n", "<leader>xi", "<cmd>UVinit<CR>", { noremap = true, silent = true, desc = "UV Init" })

    vim.api.nvim_set_keymap(
      "n",
      "<leader>xa",
      "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then run_command('uv add ' .. input) end end)<CR>",
      { noremap = true, silent = true, desc = "UV Add Package" }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>xd",
      "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then run_command('uv remove ' .. input) end end)<CR>",
      { noremap = true, silent = true, desc = "UV Remove Package" }
    )

    vim.api.nvim_set_keymap(
      "n",
      "<leader>xc",
      "<cmd>lua run_command('uv sync')<CR>",
      { noremap = true, silent = true, desc = "UV Sync Packages" }
    )
  end,
}
