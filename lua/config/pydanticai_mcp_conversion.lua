local function convert_mcp_json_in_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- Find JSON blocks with mcpServers - improved pattern matching
  local json_start = content:find('{[^{}]*"mcpServers"')
  if not json_start then
    return
  end

  -- Find the matching closing brace
  local brace_count = 0
  local json_end = json_start
  for i = json_start, #content do
    local char = content:sub(i, i)
    if char == "{" then
      brace_count = brace_count + 1
    elseif char == "}" then
      brace_count = brace_count - 1
      if brace_count == 0 then
        json_end = i
        break
      end
    end
  end

  local json_block = content:sub(json_start, json_end)
  local python_lines = {}

  -- Enhanced parser with all parameter support
  local current_server = nil
  local current_command = nil
  local current_args = nil
  local current_env = nil
  local current_url = nil
  local current_headers = nil
  local current_timeout = nil
  local current_sse_read_timeout = nil
  local current_log_level = nil
  local current_cwd = nil
  local in_args = false
  local in_env = false
  local in_headers = false
  local args_lines = {}
  local env_lines = {}
  local headers_lines = {}

  for line in json_block:gmatch("[^\r\n]+") do
    -- Find server name
    local server_name = line:match('"([^"]+)":%s*{')
    if server_name and server_name ~= "mcpServers" then
      -- Strip mcp- prefix and convert hyphens to underscores
      current_server = server_name:gsub("^mcp%-", ""):gsub("%-", "_")
    end

    -- Find all string parameters
    local command = line:match('"command":%s*"([^"]+)"')
    if command and current_server then
      current_command = command
    end

    local url = line:match('"url":%s*"([^"]+)"')
    if url and current_server then
      current_url = url
    end

    local timeout = line:match('"timeout":%s*([%d.]+)')
    if timeout and current_server then
      current_timeout = timeout
    end

    local sse_read_timeout = line:match('"sse_read_timeout":%s*([%d.]+)')
    if sse_read_timeout and current_server then
      current_sse_read_timeout = sse_read_timeout
    end

    local log_level = line:match('"log_level":%s*"([^"]+)"')
    if log_level and current_server then
      current_log_level = log_level
    end

    local cwd = line:match('"cwd":%s*"([^"]+)"')
    if cwd and current_server then
      current_cwd = cwd
    end

    -- Find args array
    if line:match('"args":%s*%[') then
      in_args = true
      args_lines = {}
      local args_on_same_line = line:match('"args":%s*(%[.-%])')
      if args_on_same_line then
        current_args = args_on_same_line:gsub(",%s*$", "")
        in_args = false
      else
        local partial = line:match('"args":%s*(%[.*)')
        if partial then
          table.insert(args_lines, partial)
        end
      end
    elseif in_args then
      local clean_line = line:match("%s*(.-)%s*$") or line
      table.insert(args_lines, clean_line)
      if line:match("%]") then
        in_args = false
        current_args = table.concat(args_lines, ""):gsub(",%s*$", "")
      end
    end

    -- Find env object
    if line:match('"env":%s*{') then
      in_env = true
      env_lines = {}
      local env_on_same_line = line:match('"env":%s*({.-})')
      if env_on_same_line then
        current_env = env_on_same_line:gsub(",%s*$", "")
        in_env = false
      else
        local partial = line:match('"env":%s*({.*)')
        if partial then
          table.insert(env_lines, partial)
        end
      end
    elseif in_env then
      local clean_line = line:match("%s*(.-)%s*$") or line
      table.insert(env_lines, clean_line)
      if line:match("}") then
        in_env = false
        current_env = table.concat(env_lines, ""):gsub(",%s*$", "")
      end
    end

    -- Find headers object
    if line:match('"headers":%s*{') then
      in_headers = true
      headers_lines = {}
      local headers_on_same_line = line:match('"headers":%s*({.-})')
      if headers_on_same_line then
        current_headers = headers_on_same_line:gsub(",%s*$", "")
        in_headers = false
      else
        local partial = line:match('"headers":%s*({.*)')
        if partial then
          table.insert(headers_lines, partial)
        end
      end
    elseif in_headers then
      local clean_line = line:match("%s*(.-)%s*$") or line
      table.insert(headers_lines, clean_line)
      if line:match("}") then
        in_headers = false
        current_headers = table.concat(headers_lines, ""):gsub(",%s*$", "")
      end
    end

    -- Check if we're at the end of this server block
    if line:match("^%s*}%s*,?%s*$") and current_server then
      if current_url then
        -- HTTP server
        local params = string.format('url="%s"', current_url)
        if current_headers then
          params = params .. string.format(", headers=%s", current_headers)
        end
        if current_timeout then
          params = params .. string.format(", timeout=%s", current_timeout)
        end
        if current_sse_read_timeout then
          params = params .. string.format(", sse_read_timeout=%s", current_sse_read_timeout)
        end
        if current_log_level then
          params = params .. string.format(', log_level="%s"', current_log_level)
        end
        -- Add tool_prefix with server name
        params = params .. string.format(', tool_prefix="%s"', current_server)

        local python_line = string.format("%s = MCPServerHTTP(%s)", current_server, params)
        table.insert(python_lines, python_line)
      elseif current_command then
        -- Stdio server
        local params = string.format('command="%s"', current_command)
        if current_args then
          params = params .. string.format(", args=%s", current_args)
        end
        if current_env then
          params = params .. string.format(", env=%s", current_env)
        end
        if current_log_level then
          params = params .. string.format(', log_level="%s"', current_log_level)
        end
        if current_cwd then
          params = params .. string.format(', cwd="%s"', current_cwd)
        end
        if current_timeout then
          params = params .. string.format(", timeout=%s", current_timeout)
        end
        -- Add tool_prefix with server name
        params = params .. string.format(', tool_prefix="%s"', current_server)

        local python_line = string.format("%s = MCPServerStdio(%s)", current_server, params)
        table.insert(python_lines, python_line)
      end

      -- Reset for next server
      current_server = nil
      current_command = nil
      current_args = nil
      current_env = nil
      current_url = nil
      current_headers = nil
      current_timeout = nil
      current_sse_read_timeout = nil
      current_log_level = nil
      current_cwd = nil
    end
  end

  if #python_lines > 0 then
    -- Replace the JSON block with Python
    local before_json = content:sub(1, json_start - 1)
    local after_json = content:sub(json_end + 1)
    local new_content = before_json .. table.concat(python_lines, "\n") .. after_json

    local new_lines = vim.split(new_content, "\n")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)

    vim.notify("Converted " .. #python_lines .. " MCP server(s)", vim.log.levels.INFO)
  end
end

-- Manual conversion functions
local function json_to_mcp_stdio()
  local start_row = vim.fn.line("'<") - 1
  local end_row = vim.fn.line("'>")

  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
  local content = table.concat(lines, "\n")

  local python_lines = {}
  -- ... similar parsing logic but force Stdio output
  local current_server = nil
  local current_command = nil
  local current_args = nil
  local current_env = nil
  local current_timeout = nil
  local current_log_level = nil
  local current_cwd = nil
  local in_args = false
  local in_env = false
  local args_lines = {}
  local env_lines = {}

  for line in content:gmatch("[^\r\n]+") do
    local server_name = line:match('"([^"]+)":%s*{')
    if server_name and server_name ~= "mcpServers" then
      current_server = server_name:gsub("^mcp%-", ""):gsub("%-", "_")
    end

    local command = line:match('"command":%s*"([^"]+)"')
    if command and current_server then
      current_command = command
    end

    local timeout = line:match('"timeout":%s*([%d.]+)')
    if timeout and current_server then
      current_timeout = timeout
    end

    local log_level = line:match('"log_level":%s*"([^"]+)"')
    if log_level and current_server then
      current_log_level = log_level
    end

    local cwd = line:match('"cwd":%s*"([^"]+)"')
    if cwd and current_server then
      current_cwd = cwd
    end

    if line:match('"args":%s*%[') then
      in_args = true
      args_lines = {}
      local args_on_same_line = line:match('"args":%s*(%[.-%])')
      if args_on_same_line then
        current_args = args_on_same_line:gsub(",%s*$", "")
        in_args = false
      else
        local partial = line:match('"args":%s*(%[.*)')
        if partial then
          table.insert(args_lines, partial)
        end
      end
    elseif in_args then
      local clean_line = line:match("%s*(.-)%s*$") or line
      table.insert(args_lines, clean_line)
      if line:match("%]") then
        in_args = false
        current_args = table.concat(args_lines, ""):gsub(",%s*$", "")
      end
    end

    if line:match('"env":%s*{') then
      in_env = true
      env_lines = {}
      local env_on_same_line = line:match('"env":%s*({.-})')
      if env_on_same_line then
        current_env = env_on_same_line:gsub(",%s*$", "")
        in_env = false
      else
        local partial = line:match('"env":%s*({.*)')
        if partial then
          table.insert(env_lines, partial)
        end
      end
    elseif in_env then
      local clean_line = line:match("%s*(.-)%s*$") or line
      table.insert(env_lines, clean_line)
      if line:match("}") then
        in_env = false
        current_env = table.concat(env_lines, ""):gsub(",%s*$", "")
      end
    end

    if line:match("^%s*}%s*,?%s*$") and current_server and current_command then
      local params = string.format('command="%s"', current_command)
      if current_args then
        params = params .. string.format(", args=%s", current_args)
      end
      if current_env then
        params = params .. string.format(", env=%s", current_env)
      end
      if current_log_level then
        params = params .. string.format(', log_level="%s"', current_log_level)
      end
      if current_cwd then
        params = params .. string.format(', cwd="%s"', current_cwd)
      end
      if current_timeout then
        params = params .. string.format(", timeout=%s", current_timeout)
      end
      params = params .. string.format(', tool_prefix="%s"', current_server)

      local python_line = string.format("%s = MCPServerStdio(%s)", current_server, params)
      table.insert(python_lines, python_line)

      current_server = nil
      current_command = nil
      current_args = nil
      current_env = nil
      current_timeout = nil
      current_log_level = nil
      current_cwd = nil
    end
  end

  if #python_lines == 0 then
    vim.notify("No MCP servers found", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(0, start_row, end_row, false, python_lines)
end

local function json_to_mcp_http()
  local start_row = vim.fn.line("'<") - 1
  local end_row = vim.fn.line("'>")

  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
  local content = table.concat(lines, "\n")

  -- For HTTP, we need to extract or prompt for URL
  local python_lines = {}
  local current_server = nil
  local current_url = nil
  local current_headers = nil
  local current_timeout = nil
  local current_sse_read_timeout = nil
  local current_log_level = nil
  local in_headers = false
  local headers_lines = {}

  for line in content:gmatch("[^\r\n]+") do
    local server_name = line:match('"([^"]+)":%s*{')
    if server_name and server_name ~= "mcpServers" then
      current_server = server_name:gsub("^mcp%-", ""):gsub("%-", "_")
    end

    local url = line:match('"url":%s*"([^"]+)"')
    if url and current_server then
      current_url = url
    end

    local timeout = line:match('"timeout":%s*([%d.]+)')
    if timeout and current_server then
      current_timeout = timeout
    end

    local sse_read_timeout = line:match('"sse_read_timeout":%s*([%d.]+)')
    if sse_read_timeout and current_server then
      current_sse_read_timeout = sse_read_timeout
    end

    local log_level = line:match('"log_level":%s*"([^"]+)"')
    if log_level and current_server then
      current_log_level = log_level
    end

    if line:match('"headers":%s*{') then
      in_headers = true
      headers_lines = {}
      local headers_on_same_line = line:match('"headers":%s*({.-})')
      if headers_on_same_line then
        current_headers = headers_on_same_line:gsub(",%s*$", "")
        in_headers = false
      else
        local partial = line:match('"headers":%s*({.*)')
        if partial then
          table.insert(headers_lines, partial)
        end
      end
    elseif in_headers then
      local clean_line = line:match("%s*(.-)%s*$") or line
      table.insert(headers_lines, clean_line)
      if line:match("}") then
        in_headers = false
        current_headers = table.concat(headers_lines, ""):gsub(",%s*$", "")
      end
    end

    if line:match("^%s*}%s*,?%s*$") and current_server then
      if not current_url then
        current_url = "http://localhost:3001/sse" -- Default URL
      end

      local params = string.format('url="%s"', current_url)
      if current_headers then
        params = params .. string.format(", headers=%s", current_headers)
      end
      if current_timeout then
        params = params .. string.format(", timeout=%s", current_timeout)
      end
      if current_sse_read_timeout then
        params = params .. string.format(", sse_read_timeout=%s", current_sse_read_timeout)
      end
      if current_log_level then
        params = params .. string.format(', log_level="%s"', current_log_level)
      end
      params = params .. string.format(', tool_prefix="%s"', current_server)

      local python_line = string.format("%s = MCPServerHTTP(%s)", current_server, params)
      table.insert(python_lines, python_line)

      current_server = nil
      current_url = nil
      current_headers = nil
      current_timeout = nil
      current_sse_read_timeout = nil
      current_log_level = nil
    end
  end

  if #python_lines == 0 then
    vim.notify("No MCP servers found", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(0, start_row, end_row, false, python_lines)
end

-- Auto-convert when text changes in Python files
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*.py",
  callback = function()
    -- Debounce to avoid too frequent calls
    vim.defer_fn(convert_mcp_json_in_buffer, 500)
  end,
  desc = "Auto-convert MCP JSON to Python",
})

-- Keymaps
vim.keymap.set("x", "<leader>mps", json_to_mcp_stdio, { desc = "Convert MCP JSON to Python Stdio" })
vim.keymap.set("x", "<leader>mph", json_to_mcp_http, { desc = "Convert MCP JSON to Python HTTP" })

-- Commands
vim.api.nvim_create_user_command("MCPJsonToStdio", json_to_mcp_stdio, { range = true })
vim.api.nvim_create_user_command("MCPJsonToHTTP", json_to_mcp_http, { range = true })
