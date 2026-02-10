local M = {}

---@class ClaudeSession
---@field id number
---@field prompt string
---@field buf number
---@field job_id number|nil
---@field state "running"|"done"|"error"
---@field exit_code number|nil
---@field created_at number

---@type ClaudeSession[]
M.sessions = {}
M._next_id = 1
M._spinner_idx = 1
M._timer = nil
M._setup_done = false

local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- Register keymaps (idempotent)
function M.setup()
  if M._setup_done then
    return
  end
  M._setup_done = true

  vim.keymap.set("n", "<leader>cc", function()
    vim.ui.input({ prompt = "Claude prompt: " }, function(prompt)
      if prompt and prompt ~= "" then
        M.create(prompt)
      end
    end)
  end, { desc = "Claude: run in background" })

  vim.keymap.set("n", "<leader>cs", function()
    M.pick()
  end, { desc = "Claude: sessions" })

  vim.keymap.set("n", "<leader>cx", function()
    M.clean()
  end, { desc = "Claude: clean finished" })
end

--- Start spinner timer to animate lualine while sessions are running
function M._start_spinner()
  if M._timer then
    return
  end
  M._timer = vim.uv.new_timer()
  M._timer:start(
    0,
    120,
    vim.schedule_wrap(function()
      M._spinner_idx = (M._spinner_idx % #spinner) + 1
      local has_running = false
      for _, s in ipairs(M.sessions) do
        if s.state == "running" and vim.api.nvim_buf_is_valid(s.buf) then
          has_running = true
          break
        end
      end
      if has_running then
        vim.cmd.redrawstatus()
      else
        if M._timer then
          M._timer:stop()
          M._timer:close()
          M._timer = nil
        end
      end
    end)
  )
end

--- Create a new background Claude session
---@param prompt string
---@return ClaudeSession
function M.create(prompt)
  local buf = vim.api.nvim_create_buf(false, false)
  local session_id = M._next_id
  M._next_id = M._next_id + 1

  local job_id
  vim.api.nvim_buf_call(buf, function()
    job_id = vim.fn.termopen("claude " .. vim.fn.shellescape(prompt), {
      on_exit = function(_, code)
        vim.schedule(function()
          for _, s in ipairs(M.sessions) do
            if s.id == session_id then
              s.state = code == 0 and "done" or "error"
              s.exit_code = code
              if code ~= 0 then
                require("snacks").notify(
                  " Claude failed: " .. s.prompt:sub(1, 50),
                  { level = "error", title = "Claude" }
                )
              else
                require("snacks").notify(
                  "󰄬 Claude done: " .. s.prompt:sub(1, 50),
                  { level = "info", title = "Claude" }
                )
              end
              vim.cmd.redrawstatus()
              break
            end
          end
        end)
      end,
    })
  end)

  local short_prompt = prompt:sub(1, 40):gsub("%s+$", "")
  vim.api.nvim_buf_set_name(buf, "claude://" .. session_id .. ": " .. short_prompt)
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
  vim.api.nvim_set_option_value("buflisted", false, { buf = buf })

  local session = {
    id = session_id,
    prompt = prompt,
    buf = buf,
    job_id = job_id,
    state = "running",
    exit_code = nil,
    created_at = os.time(),
  }

  table.insert(M.sessions, session)
  M._start_spinner()

  require("snacks").notify(
    "󰑮 Claude started: " .. prompt:sub(1, 50),
    { level = "info", title = "Claude" }
  )

  return session
end

--- Open a session in a floating window
---@param session ClaudeSession
function M.open(session)
  if not vim.api.nvim_buf_is_valid(session.buf) then
    require("snacks").notify("Session buffer no longer valid", { level = "warn", title = "Claude" })
    return
  end

  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local state_icon = ({ running = "󰑮", done = "󰄬", error = "" })[session.state]

  local win = vim.api.nvim_open_win(session.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" %s Claude: %s ", state_icon, session.prompt:sub(1, 60)),
    title_pos = "center",
  })

  -- Close float with q or <Esc> when session is finished
  if session.state ~= "running" then
    vim.keymap.set("n", "q", function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = session.buf, nowait = true })
    vim.keymap.set("n", "<Esc>", function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = session.buf, nowait = true })
  end

  -- Jump to bottom of output
  vim.cmd("normal! G")
  if session.state == "running" then
    vim.cmd.startinsert()
  end
end

--- Pick a session to open
function M.pick()
  M._clean_invalid()

  if #M.sessions == 0 then
    require("snacks").notify("No Claude sessions", { level = "info", title = "Claude" })
    return
  end

  local icons = { running = "󰑮", done = "󰄬", error = "" }

  vim.ui.select(M.sessions, {
    prompt = "Claude Sessions",
    format_item = function(s)
      local icon = icons[s.state] or "?"
      local age = os.difftime(os.time(), s.created_at)
      local time_str = age < 60 and string.format("%ds", age)
        or age < 3600 and string.format("%dm", math.floor(age / 60))
        or string.format("%dh", math.floor(age / 3600))
      return string.format("%s  %-7s │ %s │ %s ago", icon, s.state, s.prompt:sub(1, 50), time_str)
    end,
  }, function(session)
    if session then
      M.open(session)
    end
  end)
end

--- Clean up all finished (done/error) sessions
function M.clean()
  local removed = 0
  for i = #M.sessions, 1, -1 do
    local s = M.sessions[i]
    if s.state ~= "running" then
      if vim.api.nvim_buf_is_valid(s.buf) then
        vim.api.nvim_buf_delete(s.buf, { force = true })
      end
      table.remove(M.sessions, i)
      removed = removed + 1
    end
  end
  require("snacks").notify(
    removed > 0 and string.format("Cleaned %d session(s)", removed) or "No finished sessions to clean",
    { level = "info", title = "Claude" }
  )
end

--- Remove sessions with invalid buffers
function M._clean_invalid()
  M.sessions = vim.tbl_filter(function(s)
    return vim.api.nvim_buf_is_valid(s.buf)
  end, M.sessions)
end

--- Lualine status string
---@return string
function M.status()
  M._clean_invalid()
  if #M.sessions == 0 then
    return ""
  end

  local counts = { running = 0, done = 0, error = 0 }
  for _, s in ipairs(M.sessions) do
    counts[s.state] = (counts[s.state] or 0) + 1
  end

  local parts = {}
  if counts.running > 0 then
    table.insert(parts, spinner[M._spinner_idx] .. " " .. counts.running)
  end
  if counts.error > 0 then
    table.insert(parts, " " .. counts.error)
  end
  if counts.done > 0 then
    table.insert(parts, "󰄬 " .. counts.done)
  end

  return "󰚩 " .. table.concat(parts, " ")
end

--- Lualine color — priority: error (red) > running (blue) > done (green)
---@return table
function M.status_color()
  for _, s in ipairs(M.sessions) do
    if s.state == "error" then
      return { fg = "#f7768e" }
    end
  end
  for _, s in ipairs(M.sessions) do
    if s.state == "running" then
      return { fg = "#7aa2f7" }
    end
  end
  return { fg = "#9ece6a" }
end

return M
