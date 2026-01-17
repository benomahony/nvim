return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local quotes_file = vim.fn.expand("~/writing/building-ai-agent-platforms/quotes.asciidoc")
    
    local function parse_quotes()
      local quotes = {}
      local lines = vim.fn.readfile(quotes_file)
      local current_quote = nil
      
      for _, line in ipairs(lines) do
        if line:match("^%[quote,") then
          if current_quote then
            table.insert(quotes, current_quote)
          end
          current_quote = {
            attribution = line:match("^%[quote,%s*(.-)%s*%]"),
            lines = {},
            raw_attr = line,
          }
        elseif current_quote and line:match("^____") then
          if #current_quote.lines > 0 then
            table.insert(quotes, current_quote)
            current_quote = nil
          end
        elseif current_quote and line ~= "" then
          table.insert(current_quote.lines, line)
        end
      end
      
      return quotes
    end
    
    local function insert_quote(quote)
      local lines = { "", quote.raw_attr, "____" }
      for _, line in ipairs(quote.lines) do
        table.insert(lines, line)
      end
      table.insert(lines, "____")
      vim.api.nvim_put(lines, "l", true, true)
      
      local quotes_content = vim.fn.readfile(quotes_file)
      local new_content = {}
      local skip_until_end = false
      
      for i, line in ipairs(quotes_content) do
        if line == quote.raw_attr then
          skip_until_end = true
        elseif skip_until_end and line:match("^____") then
          skip_until_end = false
        elseif not skip_until_end then
          table.insert(new_content, line)
        end
      end
      
      vim.fn.writefile(new_content, quotes_file)
      vim.notify("Quote moved to chapter", vim.log.levels.INFO)
    end
    
    local function remove_quote_at_cursor()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line_num = cursor[1]
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      
      local start_line = nil
      local end_line = nil
      
      for i = line_num, 1, -1 do
        if lines[i]:match("^%[quote,") then
          start_line = i
          break
        end
      end
      
      if start_line then
        for i = start_line, #lines do
          if i > start_line and (lines[i]:match("^%[quote,") or lines[i]:match("^==") or lines[i]:match("^===")) then
            end_line = i - 1
            break
          end
        end
        end_line = end_line or #lines
        
        while end_line > start_line and lines[end_line]:match("^%s*$") do
          end_line = end_line - 1
        end
        
        local quote_lines = vim.list_slice(lines, start_line, end_line)
        
        local quotes_content = vim.fn.readfile(quotes_file)
        table.insert(quotes_content, "")
        for _, line in ipairs(quote_lines) do
          table.insert(quotes_content, line)
        end
        table.insert(quotes_content, "____")
        vim.fn.writefile(quotes_content, quotes_file)
        
        vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, {})
        vim.notify("Quote moved to quotes.asciidoc", vim.log.levels.INFO)
      else
        vim.notify("No quote found at cursor", vim.log.levels.WARN)
      end
    end
    
    vim.keymap.set("n", "<leader>qa", function()
      local quotes = parse_quotes()
      
      vim.ui.select(quotes, {
        prompt = "Select quote:",
        format_item = function(quote)
          local preview = table.concat(quote.lines, " "):sub(1, 80)
          if #preview == 80 then preview = preview .. "..." end
          return quote.attribution .. ' - "' .. preview .. '"'
        end,
      }, function(choice)
        if choice then
          insert_quote(choice)
        end
      end)
    end, { desc = "Add quote" })
    
    vim.keymap.set("n", "<leader>qr", remove_quote_at_cursor, { desc = "Remove quote" })
    
    return opts
  end,
}
