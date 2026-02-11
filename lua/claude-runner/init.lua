local M = {}

---@class ClaudeSession
---@field id number
---@field prompt string
---@field buf number
---@field job_id number|nil
---@field state "working"|"idle"
---@field created_at number
---@field last_activity number

---@type ClaudeSession[]
M.sessions = {}
M._next_id = 1
M._spinner_idx = 1
M._timer = nil
M._setup_done = false
M._session_keymaps = {}
M._current_session_idx = 1

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
  end, { desc = "Claude: clean idle" })

  vim.keymap.set("n", "<leader>cn", function()
    M.cycle_next()
  end, { desc = "Claude: next session" })

  vim.keymap.set("n", "<leader>cp", function()
    M.cycle_prev()
  end, { desc = "Claude: prev session" })
end

--- Update dynamic keybindings for sessions
function M._update_keybindings()
  -- Clear old keymaps
  for _, km in ipairs(M._session_keymaps) do
    pcall(vim.keymap.del, "n", km)
  end
  M._session_keymaps = {}

  -- Create new keymaps for current sessions
  M._clean_invalid()
  for i, session in ipairs(M.sessions) do
    if i <= 9 then
      local key = "<leader>c" .. i
      vim.keymap.set("n", key, function()
        M.open(session)
      end, { desc = "Claude: open session " .. i })
      table.insert(M._session_keymaps, key)
    end
  end
end

--- Check if sessions are still valid (jobs still running)
function M._update_session_activity()
  for _, s in ipairs(M.sessions) do
    if vim.api.nvim_buf_is_valid(s.buf) and s.job_id then
      -- Verify job is still running (on_exit callback handles cleanup)
      local job_status = vim.fn.jobwait({ s.job_id }, 0)[1]
      -- job_status == -1 means still running
      -- Activity tracking is now handled by stdout/stderr callbacks
    end
  end
end

--- Start spinner timer to animate lualine while sessions are running
function M._start_spinner()
  if M._timer then
    return
  end
  M._timer = vim.uv.new_timer()
  M._timer:start(
    0,
    500, -- Poll every 500ms to catch status changes
    vim.schedule_wrap(function()
      M._spinner_idx = (M._spinner_idx % #spinner) + 1

      -- Update activity status
      M._update_session_activity()

      -- Always redraw to update status
      vim.cmd.redrawstatus()

      -- Stop timer when no background sessions
      if #M.sessions == 0 then
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
  local function update_activity()
    for _, s in ipairs(M.sessions) do
      if s.id == session_id then
        s.last_activity = os.time()
        break
      end
    end
  end

  vim.api.nvim_buf_call(buf, function()
    job_id = vim.fn.termopen("claude --dangerously-skip-permissions " .. vim.fn.shellescape(prompt), {
      on_stdout = function(_, data, _)
        if data and #data > 0 then
          vim.schedule(update_activity)
        end
      end,
      on_stderr = function(_, data, _)
        if data and #data > 0 then
          vim.schedule(update_activity)
        end
      end,
      on_exit = function(_, code)
        vim.schedule(function()
          for i, s in ipairs(M.sessions) do
            if s.id == session_id then
              -- Remove session when process exits
              if vim.api.nvim_buf_is_valid(s.buf) then
                vim.api.nvim_buf_delete(s.buf, { force = true })
              end
              table.remove(M.sessions, i)
              M._update_keybindings()

              local msg = code == 0 and "󰄬 Claude finished" or " Claude failed"
              require("snacks").notify(
                string.format("%s: %s", msg, s.prompt:sub(1, 50)),
                { level = code == 0 and "info" or "error", title = "Claude" }
              )
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
    state = "working",
    created_at = os.time(),
    last_activity = os.time(),
  }

  table.insert(M.sessions, session)
  M._start_spinner()
  M._update_keybindings()

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

  -- Update current session index for cycling
  for i, s in ipairs(M.sessions) do
    if s.id == session.id then
      M._current_session_idx = i
      break
    end
  end

  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local idle_time = os.time() - session.last_activity
  local state_icon = idle_time > 0 and "" or "󰑮"

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

  -- Close float with q or <Esc> (normal mode)
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

  -- Close float from terminal mode (for running sessions)
  vim.keymap.set("t", "<Esc><Esc>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = session.buf, nowait = true })
  vim.keymap.set("t", "<C-q>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = session.buf, nowait = true })

  -- Cycle sessions from terminal mode
  vim.keymap.set("t", "<C-n>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.schedule(function()
      M.cycle_next()
    end)
  end, { buffer = session.buf, nowait = true })
  vim.keymap.set("t", "<C-p>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.schedule(function()
      M.cycle_prev()
    end)
  end, { buffer = session.buf, nowait = true })

  -- Jump to bottom of output and enter insert mode for terminal
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.cmd("normal! G")
      vim.cmd.startinsert()
    end
  end)
end

--- Pick a session to open
function M.pick()
  M._clean_invalid()

  if #M.sessions == 0 then
    require("snacks").notify("No Claude sessions", { level = "info", title = "Claude" })
    return
  end

  vim.ui.select(M.sessions, {
    prompt = "Claude Sessions",
    format_item = function(s)
      local idle_time = os.time() - s.last_activity
      local icon = idle_time > 0 and "" or "󰑮"
      local state = idle_time > 0 and "waiting" or "working"
      local age = os.difftime(os.time(), s.created_at)
      local time_str = age < 60 and string.format("%ds", age)
        or age < 3600 and string.format("%dm", math.floor(age / 60))
        or string.format("%dh", math.floor(age / 3600))
      return string.format("%s  %-7s │ %s │ %s ago", icon, state, s.prompt:sub(1, 50), time_str)
    end,
  }, function(session)
    if session then
      M.open(session)
    end
  end)
end

--- Clean up idle sessions (>5 minutes of inactivity)
function M.clean()
  local removed = 0
  local now = os.time()
  for i = #M.sessions, 1, -1 do
    local s = M.sessions[i]
    local idle_time = now - s.last_activity
    if idle_time > 300 then -- 5 minutes
      if vim.api.nvim_buf_is_valid(s.buf) then
        vim.api.nvim_buf_delete(s.buf, { force = true })
      end
      table.remove(M.sessions, i)
      removed = removed + 1
    end
  end
  M._update_keybindings()
  require("snacks").notify(
    removed > 0 and string.format("Cleaned %d idle session(s)", removed) or "No idle sessions to clean",
    { level = "info", title = "Claude" }
  )
end

--- Remove sessions with invalid buffers
function M._clean_invalid()
  M.sessions = vim.tbl_filter(function(s)
    return vim.api.nvim_buf_is_valid(s.buf)
  end, M.sessions)

  -- Reset index if out of bounds
  if M._current_session_idx > #M.sessions then
    M._current_session_idx = math.max(1, #M.sessions)
  end
end

--- Get status for a specific session
---@param index number
---@return string
function M.session_status(index)
  M._clean_invalid()
  local session = M.sessions[index]
  if not session then
    return ""
  end

  local idle_time = os.time() - session.last_activity
  local icon = idle_time > 0 and "" or spinner[M._spinner_idx]
  local short_prompt = session.prompt:sub(1, 20):gsub("%s+$", "")
  return string.format("󰚩 %s %d:%s", icon, index, short_prompt)
end

--- Get color for a specific session
---@param index number
---@return table
function M.session_color(index)
  M._clean_invalid()
  local session = M.sessions[index]
  if not session then
    return { fg = "#666666" }
  end

  local idle_time = os.time() - session.last_activity
  if idle_time > 0 then
    return { fg = "#f7768e" } -- Red when idle/needs input
  else
    return { fg = "#9ece6a" } -- Green when actively working
  end
end

--- Check if session exists
---@param index number
---@return boolean
function M.has_session(index)
  M._clean_invalid()
  return M.sessions[index] ~= nil
end

--- Open session by index
---@param index number
function M.open_session(index)
  M._clean_invalid()
  local session = M.sessions[index]
  if session then
    M.open(session)
  end
end

--- Cycle to next session
function M.cycle_next()
  M._clean_invalid()
  if #M.sessions == 0 then
    require("snacks").notify("No Claude sessions", { level = "info", title = "Claude" })
    return
  end

  M._current_session_idx = (M._current_session_idx % #M.sessions) + 1
  M.open(M.sessions[M._current_session_idx])
end

--- Cycle to previous session
function M.cycle_prev()
  M._clean_invalid()
  if #M.sessions == 0 then
    require("snacks").notify("No Claude sessions", { level = "info", title = "Claude" })
    return
  end

  M._current_session_idx = M._current_session_idx - 1
  if M._current_session_idx < 1 then
    M._current_session_idx = #M.sessions
  end
  M.open(M.sessions[M._current_session_idx])
end

return M
