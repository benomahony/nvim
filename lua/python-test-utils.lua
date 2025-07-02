local M = {}

-- Coverage module
M.coverage = {}

-- Navigation module
M.navigation = {}

-- Test generation module
M.generation = {}

-- Plugin state
local coverage_data = {}
local coverage_visible = false
local signs_placed = {}

-- Sign definitions
local function setup_signs()
  vim.fn.sign_define("CoverageCovered", {
    text = "▐",
    texthl = "CoverageCovered",
  })
  vim.fn.sign_define("CoverageUncovered", {
    text = "▐",
    texthl = "CoverageUncovered",
  })
end

-- Setup highlight groups
local function setup_highlights()
  vim.api.nvim_set_hl(0, "CoverageCovered", { fg = "#C3E88D" })
  vim.api.nvim_set_hl(0, "CoverageUncovered", { fg = "#F07178" })
end

-- Parse coverage.json file
local function parse_coverage_json(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end

  return data
end

-- Find coverage file in project root
local function find_coverage_file()
  local root = require("lazyvim.util").root.get()
  local files = {
    root .. "/coverage.json",
    root .. "/.coverage",
    root .. "/coverage.xml",
  }

  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then
      return file
    end
  end

  return nil
end

-- Clear all coverage signs
local function clear_signs()
  local namespace = vim.api.nvim_create_namespace("coverage")
  for buf, _ in pairs(signs_placed) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
    end
  end
  signs_placed = {}
end

-- Place signs for a buffer
local function place_signs_for_buffer(bufnr)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  if file_path == "" then
    return
  end

  -- Clear existing signs for this buffer first
  local namespace = vim.api.nvim_create_namespace("coverage")
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end

  -- Convert absolute path to relative path from project root
  local root = require("lazyvim.util").root.get()
  local relative_path = file_path:gsub("^" .. vim.pesc(root) .. "/", "")

  -- Look for this file in coverage data
  local file_coverage = nil
  for path, data in pairs(coverage_data) do
    if path == relative_path or path:match(relative_path .. "$") then
      file_coverage = data
      break
    end
  end

  if not file_coverage then
    return
  end

  signs_placed[bufnr] = {}
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  -- Place virtual text for executed lines (covered)
  if file_coverage.executed_lines then
    for _, line_num in ipairs(file_coverage.executed_lines) do
      if line_num <= line_count then
        vim.api.nvim_buf_set_extmark(bufnr, namespace, line_num - 1, -1, {
          virt_text = { { "▐", "CoverageCovered" } },
          virt_text_pos = "right_align",
        })
      end
    end
  end

  -- Place virtual text for missing lines (uncovered)
  if file_coverage.missing_lines then
    for _, line_num in ipairs(file_coverage.missing_lines) do
      if line_num <= line_count then
        vim.api.nvim_buf_set_extmark(bufnr, namespace, line_num - 1, -1, {
          virt_text = { { "▐", "CoverageUncovered" } },
          virt_text_pos = "right_align",
        })
      end
    end
  end
end

-- TEST GENERATION HELPER FUNCTIONS

-- Parse function parameters into structured data
local function parse_function_parameters(params_string)
  if not params_string or params_string == "" then
    return {}
  end

  local params = {}
  local current_param = ""
  local paren_depth = 0
  local in_string = false
  local string_char = nil

  for i = 1, #params_string do
    local char = params_string:sub(i, i)

    if not in_string then
      if char == '"' or char == "'" then
        in_string = true
        string_char = char
        current_param = current_param .. char
      elseif char == "(" or char == "[" then
        paren_depth = paren_depth + 1
        current_param = current_param .. char
      elseif char == ")" or char == "]" then
        paren_depth = paren_depth - 1
        current_param = current_param .. char
      elseif char == "," and paren_depth == 0 then
        -- Found parameter boundary
        if current_param:match("%S") then
          table.insert(params, current_param:match("^%s*(.-)%s*$"))
        end
        current_param = ""
      else
        current_param = current_param .. char
      end
    else
      if char == string_char then
        in_string = false
        string_char = nil
      end
      current_param = current_param .. char
    end
  end

  -- Add the last parameter
  if current_param:match("%S") then
    table.insert(params, current_param:match("^%s*(.-)%s*$"))
  end

  local parsed_params = {}
  for _, param in ipairs(params) do
    if param ~= "self" then -- Skip self parameter
      local name, param_type, default = param:match("^([%w_]+)%s*:%s*([^=]+)%s*=%s*(.+)$")
      if not name then
        name, param_type = param:match("^([%w_]+)%s*:%s*(.+)$")
      end
      if not name then
        name, default = param:match("^([%w_]+)%s*=%s*(.+)$")
      end
      if not name then
        name = param:match("^([%w_]+)$")
      end

      if name then
        table.insert(parsed_params, {
          name = name,
          type = param_type and param_type:match("^%s*(.-)%s*$") or nil,
          default = default and default:match("^%s*(.-)%s*$") or nil,
        })
      end
    end
  end

  return parsed_params
end

-- Convert file path to Python import path
local function get_module_import_path(file_path)
  local root = require("lazyvim.util").root.get()
  local relative_path = file_path:gsub("^" .. vim.pesc(root) .. "/", "")

  -- Remove .py extension
  local import_path = relative_path:gsub("%.py$", "")

  -- Convert path separators to dots
  import_path = import_path:gsub("/", ".")

  -- Handle __init__.py files
  import_path = import_path:gsub("%.__init__$", "")

  return import_path
end

-- Suggest test values for parameters based on type and name
local function suggest_parameter_values(param_name, param_type)
  -- Type-based suggestions
  if param_type then
    local clean_type = param_type:gsub("^%s*(.-)%s*$", "%1"):lower()
    if clean_type:match("str") then
      return '"test_string"'
    elseif clean_type:match("int") then
      return "42"
    elseif clean_type:match("float") then
      return "3.14"
    elseif clean_type:match("bool") then
      return "True"
    elseif clean_type:match("list") then
      return "[1, 2, 3]"
    elseif clean_type:match("dict") then
      return '{"key": "value"}'
    end
  end

  -- Name-based suggestions
  local name_lower = param_name:lower()
  if name_lower:match("id") or name_lower:match("count") or name_lower:match("num") then
    return "1"
  elseif name_lower:match("name") or name_lower:match("title") then
    return '"test_name"'
  elseif name_lower:match("email") then
    return '"test@example.com"'
  elseif name_lower:match("url") or name_lower:match("uri") then
    return '"https://example.com"'
  elseif name_lower:match("path") then
    return '"/tmp/test"'
  elseif name_lower:match("flag") or name_lower:match("enable") or name_lower:match("active") then
    return "True"
  end

  return "None  # TODO: provide test value"
end

-- Generate appropriate assertions based on function analysis
local function generate_assertions(func_name, return_type)
  local assertions = {}

  -- Return type based assertions
  if return_type then
    local clean_type = return_type:gsub("^%s*(.-)%s*$", "%1"):lower()
    if clean_type:match("str") then
      table.insert(assertions, "assert isinstance(result, str)")
      table.insert(assertions, "assert len(result) > 0")
    elseif clean_type:match("int") or clean_type:match("float") then
      table.insert(assertions, "assert isinstance(result, (int, float))")
    elseif clean_type:match("bool") then
      table.insert(assertions, "assert isinstance(result, bool)")
    elseif clean_type:match("list") then
      table.insert(assertions, "assert isinstance(result, list)")
    elseif clean_type:match("dict") then
      table.insert(assertions, "assert isinstance(result, dict)")
    elseif clean_type:match("none") then
      table.insert(assertions, "assert result is None")
    end
  end

  -- Function name based assertions
  local name_lower = func_name:lower()
  if name_lower:match("^get_") then
    table.insert(assertions, "assert result is not None")
  elseif name_lower:match("^is_") or name_lower:match("^has_") or name_lower:match("^can_") then
    table.insert(assertions, "assert isinstance(result, bool)")
  elseif name_lower:match("^create_") or name_lower:match("^make_") then
    table.insert(assertions, "assert result is not None")
  elseif name_lower:match("^validate_") or name_lower:match("^check_") then
    table.insert(assertions, "# Add validation assertions based on expected outcome")
  elseif name_lower:match("^find_") or name_lower:match("^search_") then
    table.insert(assertions, "# Assert search results match expected criteria")
  elseif name_lower:match("^update_") or name_lower:match("^set_") then
    table.insert(assertions, "# Assert state was updated correctly")
  elseif name_lower:match("^delete_") or name_lower:match("^remove_") then
    table.insert(assertions, "# Assert item was removed/deleted")
  end

  -- If no specific assertions were generated, add a generic one
  if #assertions == 0 then
    table.insert(assertions, "assert result is not None  # TODO: add specific assertions")
  end

  return assertions
end

-- Get function signature from current cursor position using treesitter
local function get_current_function_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2] -- Convert to 0-based

  -- Get treesitter parser
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
  if not ok then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  -- Find the function definition that contains the cursor
  local function find_function_at_cursor(node)
    if node:type() == "function_definition" then
      local start_row, start_col, end_row, end_col = node:range()
      if start_row <= row and row <= end_row then
        -- Found the function containing the cursor
        local func_name = nil
        local params = nil
        local class_name = nil

        -- Get function name
        for child in node:iter_children() do
          if child:type() == "identifier" then
            func_name = vim.treesitter.get_node_text(child, bufnr)
            break
          end
        end

        -- Get parameters
        for child in node:iter_children() do
          if child:type() == "parameters" then
            params = vim.treesitter.get_node_text(child, bufnr)
            -- Remove parentheses
            params = params:gsub("^%((.*)%)$", "%1")
            break
          end
        end

        -- Get return type annotation
        local return_type = nil
        for child in node:iter_children() do
          if child:type() == "type" then
            return_type = vim.treesitter.get_node_text(child, bufnr)
            break
          end
        end

        -- Find parent class if this is a method
        local parent = node:parent()
        while parent do
          if parent:type() == "class_definition" then
            for child in parent:iter_children() do
              if child:type() == "identifier" then
                class_name = vim.treesitter.get_node_text(child, bufnr)
                break
              end
            end
            break
          end
          parent = parent:parent()
        end

        return {
          name = func_name,
          params = params,
          return_type = return_type,
          class_name = class_name,
          line_start = start_row + 1, -- Convert back to 1-based
          line_current = row + 1,
        }
      end
    end

    -- Recursively search children
    for child in node:iter_children() do
      local result = find_function_at_cursor(child)
      if result then
        return result
      end
    end

    return nil
  end

  return find_function_at_cursor(root)
end

-- Check if current line/function is covered
local function is_function_covered(func_info)
  if not coverage_data or vim.tbl_isempty(coverage_data) then
    return nil, "No coverage data loaded"
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  local root = require("lazyvim.util").root.get()
  local relative_path = file_path:gsub("^" .. vim.pesc(root) .. "/", "")

  -- Find file in coverage data
  local file_coverage = nil
  for path, data in pairs(coverage_data) do
    if path == relative_path or path:match(relative_path .. "$") then
      file_coverage = data
      break
    end
  end

  if not file_coverage then
    return nil, "No coverage data for this file"
  end

  -- Check if function lines are covered
  local executed_lines = file_coverage.executed_lines or {}
  local missing_lines = file_coverage.missing_lines or {}

  local function_executed = false
  local function_missing = false

  -- Check lines around the function
  for line = func_info.line_start, func_info.line_start + 10 do
    for _, exec_line in ipairs(executed_lines) do
      if exec_line == line then
        function_executed = true
        break
      end
    end

    for _, miss_line in ipairs(missing_lines) do
      if miss_line == line then
        function_missing = true
        break
      end
    end
  end

  if function_missing then
    return false, "Function has missing coverage"
  elseif function_executed then
    return true, "Function is covered"
  else
    return nil, "Cannot determine coverage status"
  end
end

-- Generate test template for a function
local function generate_test_template(func_info, test_purpose)
  local test_name = "test_" .. func_info.name
  if test_purpose then
    test_name = test_name .. "_" .. test_purpose:gsub("%s+", "_"):lower()
  end

  local template = {}

  -- Get the proper module import path
  local current_file = vim.api.nvim_buf_get_name(0)
  local module_path = get_module_import_path(current_file)

  -- Parse function parameters
  local params = parse_function_parameters(func_info.params)

  -- Add imports
  table.insert(template, "import pytest")
  if func_info.class_name then
    table.insert(template, "from " .. module_path .. " import " .. func_info.class_name)
  else
    table.insert(template, "from " .. module_path .. " import " .. func_info.name)
  end
  table.insert(template, "")
  table.insert(template, "")

  -- Generate test function
  table.insert(template, "def " .. test_name .. "():")
  table.insert(template, '    """Test ' .. func_info.name .. (func_info.class_name and " method." or " function."))
  if test_purpose then
    table.insert(template, "    " .. test_purpose)
  end
  table.insert(template, '    """')
  table.insert(template, "    # Arrange")

  if func_info.class_name then
    table.insert(template, "    instance = " .. func_info.class_name .. "()")
    if #params > 0 then
      for _, param in ipairs(params) do
        local value = suggest_parameter_values(param.name, param.type)
        table.insert(template, "    " .. param.name .. " = " .. value)
      end
    end
    table.insert(template, "    ")
    table.insert(template, "    # Act")
    if #params > 0 then
      local param_names = {}
      for _, param in ipairs(params) do
        table.insert(param_names, param.name)
      end
      table.insert(
        template,
        "    result = instance." .. func_info.name .. "(" .. table.concat(param_names, ", ") .. ")"
      )
    else
      table.insert(template, "    result = instance." .. func_info.name .. "()")
    end
  else
    if #params > 0 then
      for _, param in ipairs(params) do
        local value = suggest_parameter_values(param.name, param.type)
        table.insert(template, "    " .. param.name .. " = " .. value)
      end
    end
    table.insert(template, "    ")
    table.insert(template, "    # Act")
    if #params > 0 then
      local param_names = {}
      for _, param in ipairs(params) do
        table.insert(param_names, param.name)
      end
      table.insert(template, "    result = " .. func_info.name .. "(" .. table.concat(param_names, ", ") .. ")")
    else
      table.insert(template, "    result = " .. func_info.name .. "()")
    end
  end

  table.insert(template, "    ")
  table.insert(template, "    # Assert")

  -- Generate appropriate assertions
  local assertions = generate_assertions(func_info.name, func_info.return_type)
  for _, assertion in ipairs(assertions) do
    table.insert(template, "    " .. assertion)
  end

  return template
end

-- COVERAGE MODULE FUNCTIONS

-- Load coverage data
function M.coverage.load()
  local coverage_file = find_coverage_file()
  if not coverage_file then
    require("snacks").notify("❌ No coverage file found", {
      title = "Coverage",
      level = "error",
      timeout = 2000,
    })
    return
  end

  -- Only support coverage.json for now (simplest to parse)
  if not coverage_file:match("coverage%.json$") then
    require("snacks").notify("❌ Only coverage.json supported for now", {
      title = "Coverage",
      level = "error",
      timeout = 2000,
    })
    return
  end

  local data = parse_coverage_json(coverage_file)
  if not data or not data.files then
    require("snacks").notify("❌ Failed to parse coverage file", {
      title = "Coverage",
      level = "error",
      timeout = 2000,
    })
    return
  end

  coverage_data = data.files
  coverage_visible = true

  -- Place signs in all Python buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local file_path = vim.api.nvim_buf_get_name(bufnr)
      if file_path:match("%.py$") then
        place_signs_for_buffer(bufnr)
      end
    end
  end

  require("snacks").notify("📊 Coverage loaded successfully\n🔍 Check right hand side for indicators", {
    title = "Coverage Active",
    timeout = 2000,
  })
end

-- Toggle coverage (auto-loads if not loaded)
function M.coverage.toggle()
  if coverage_visible then
    clear_signs()
    coverage_visible = false
    require("snacks").notify("📊 Coverage hidden\n🔍 Use <leader>tx to show again", {
      title = "Coverage Disabled",
      timeout = 2000,
    })
  else
    -- Auto-load coverage when toggling on
    M.coverage.load()
  end
end

-- Show coverage summary for current buffer
function M.coverage.buffer_summary()
  if not coverage_data or vim.tbl_isempty(coverage_data) then
    require("snacks").notify("❌ No coverage data loaded\nUse <leader>tx to load coverage first", {
      title = "Coverage",
      level = "error",
      timeout = 2000,
    })
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)

  if file_path == "" or not file_path:match("%.py$") then
    require("snacks").notify("❌ Not a Python file\nOpen a Python file to see buffer coverage", {
      title = "Buffer Coverage",
      level = "error",
      timeout = 2000,
    })
    return
  end

  -- Convert absolute path to relative path from project root
  local root = require("lazyvim.util").root.get()
  local relative_path = file_path:gsub("^" .. vim.pesc(root) .. "/", "")

  -- Look for this file in coverage data
  local file_coverage = nil
  for path, data in pairs(coverage_data) do
    if path == relative_path or path:match(relative_path .. "$") then
      file_coverage = data
      break
    end
  end

  if not file_coverage or not file_coverage.summary then
    require("snacks").notify("❌ No coverage data for this file\n📄 " .. vim.fn.fnamemodify(file_path, ":t"), {
      title = "Buffer Coverage",
      level = "warn",
      timeout = 2000,
    })
    return
  end

  local summary = file_coverage.summary
  local line_percentage = summary.num_statements > 0 and (summary.covered_lines / summary.num_statements * 100) or 0
  local branch_percentage = summary.num_branches > 0 and (summary.covered_branches / summary.num_branches * 100) or 0

  local message = string.format(
    "📄 %s\n"
      .. "📝 Lines: %.1f%% (%d/%d covered)\n"
      .. "🌳 Branches: %.1f%% (%d/%d covered)\n"
      .. "⚠️  Partial branches: %d\n"
      .. "❌ Missing lines: %d",
    vim.fn.fnamemodify(file_path, ":t"),
    line_percentage,
    summary.covered_lines,
    summary.num_statements,
    branch_percentage,
    summary.covered_branches,
    summary.num_branches,
    summary.num_partial_branches,
    summary.missing_lines
  )

  require("snacks").notify(message, {
    title = "Buffer Coverage",
    timeout = 2000,
  })
end

-- Show coverage summary for whole project
function M.coverage.project_summary()
  if not coverage_data or vim.tbl_isempty(coverage_data) then
    require("snacks").notify("❌ No coverage data loaded\nUse <leader>tx to load coverage first", {
      title = "Coverage",
      level = "error",
      timeout = 2000,
    })
    return
  end

  local total_statements = 0
  local total_covered = 0
  local total_branches = 0
  local total_covered_branches = 0
  local total_partial_branches = 0
  local files_count = 0

  for _, file_data in pairs(coverage_data) do
    if file_data.summary then
      total_statements = total_statements + (file_data.summary.num_statements or 0)
      total_covered = total_covered + (file_data.summary.covered_lines or 0)
      total_branches = total_branches + (file_data.summary.num_branches or 0)
      total_covered_branches = total_covered_branches + (file_data.summary.covered_branches or 0)
      total_partial_branches = total_partial_branches + (file_data.summary.num_partial_branches or 0)
      files_count = files_count + 1
    end
  end

  local line_percentage = total_statements > 0 and (total_covered / total_statements * 100) or 0
  local branch_percentage = total_branches > 0 and (total_covered_branches / total_branches * 100) or 0

  local message = string.format(
    "📊 Coverage Summary\n"
      .. "📝 Lines: %.1f%% (%d/%d covered)\n"
      .. "🌳 Branches: %.1f%% (%d/%d covered)\n"
      .. "⚠️  Partial branches: %d\n"
      .. "📁 Files analyzed: %d",
    line_percentage,
    total_covered,
    total_statements,
    branch_percentage,
    total_covered_branches,
    total_branches,
    total_partial_branches,
    files_count
  )

  require("snacks").notify(message, {
    title = "Coverage Statistics",
    timeout = 2000,
  })
end

-- NAVIGATION MODULE FUNCTIONS

-- Go to test/source file
function M.navigation.go_to_test()
  local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")

  if current:match("^tests/") then
    -- Going from test to source
    local source = current:gsub("^tests/", ""):gsub("_test%.py$", ".py")
    if vim.fn.filereadable(source) == 1 then
      vim.cmd("edit " .. source)
      require("snacks").notify("📝 Switched to source: " .. source, { title = "Test → Source", timeout = 2000 })
    else
      require("snacks").notify(
        "❌ Source file not found: " .. source,
        { title = "Error", level = "error", timeout = 2000 }
      )
    end
  else
    -- Going from source to test
    local without_ext = current:gsub("%.py$", "")
    local test_file = "tests/" .. without_ext .. "_test.py"

    if vim.fn.filereadable(test_file) == 1 then
      vim.cmd("edit " .. test_file)
      require("snacks").notify("🧪 Switched to test: " .. test_file, { title = "Source → Test", timeout = 2000 })
    else
      vim.ui.select({ "Yes", "No" }, {
        prompt = "🆕 Create test file: " .. test_file .. "?",
      }, function(choice)
        if choice == "Yes" then
          vim.fn.mkdir(vim.fn.fnamemodify(test_file, ":h"), "p")
          vim.cmd("edit " .. test_file)
          require("snacks").notify("✨ Created test: " .. test_file, { title = "New Test File", timeout = 2000 })
        end
      end)
    end
  end
end

-- TEST GENERATION MODULE FUNCTIONS

-- Generate test for current function
function M.generation.generate_test_for_function()
  local func_info = get_current_function_info()
  if not func_info then
    require("snacks").notify("❌ Not inside a function\nPlace cursor inside a function to generate tests", {
      title = "Test Generation",
      level = "error",
      timeout = 2000,
    })
    return
  end

  -- Show what function was detected
  local func_desc = func_info.name
  if func_info.class_name then
    func_desc = func_info.class_name .. "." .. func_info.name
  end

  -- Check coverage status
  local is_covered, coverage_msg = is_function_covered(func_info)
  local test_purpose = nil

  if is_covered == false then
    test_purpose = "Covers missing lines in " .. func_info.name
    require("snacks").notify("🎯 Generating test for uncovered function: " .. func_desc, {
      title = "Test Generation",
      timeout = 2000,
    })
  elseif is_covered == true then
    test_purpose = "Additional test for " .. func_info.name
    require("snacks").notify("📝 Generating additional test for: " .. func_desc, {
      title = "Test Generation",
      timeout = 2000,
    })
  else
    test_purpose = "Test for " .. func_info.name
    require("snacks").notify("🧪 Generating test for: " .. func_desc .. "\n" .. coverage_msg, {
      title = "Test Generation",
      timeout = 2000,
    })
  end

  -- Generate test template
  local template = generate_test_template(func_info, test_purpose)

  -- Navigate to test file and insert template
  M.navigation.go_to_test()

  -- Wait for file to open, then insert template
  vim.defer_fn(function()
    local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
    if current_file:match("_test%.py$") then
      -- Find a good place to insert the test (end of file)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local insert_line = #lines

      -- Add some spacing if file isn't empty
      if #lines > 0 and lines[#lines] ~= "" then
        table.insert(template, 1, "")
        table.insert(template, 1, "")
      end

      -- Insert the template
      vim.api.nvim_buf_set_lines(0, insert_line, insert_line, false, template)

      -- Move cursor to the first TODO
      for i, line in ipairs(template) do
        if line:match("TODO") then
          vim.api.nvim_win_set_cursor(0, { insert_line + i, 0 })
          break
        end
      end

      require("snacks").notify("✨ Test template generated!\n🔧 Fill in TODOs and adjust imports", {
        title = "Test Generated",
        timeout = 2000,
      })
    end
  end, 500)
end

-- Generate test for missing coverage in current file
function M.generation.generate_test_for_missing()
  if not coverage_data or vim.tbl_isempty(coverage_data) then
    require("snacks").notify("❌ No coverage data loaded\nUse <leader>tx to load coverage first", {
      title = "Test Generation",
      level = "error",
      timeout = 2000,
    })
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  local root = require("lazyvim.util").root.get()
  local relative_path = file_path:gsub("^" .. vim.pesc(root) .. "/", "")

  -- Find file in coverage data
  local file_coverage = nil
  for path, data in pairs(coverage_data) do
    if path == relative_path or path:match(relative_path .. "$") then
      file_coverage = data
      break
    end
  end

  if not file_coverage then
    require("snacks").notify("❌ No coverage data for this file", {
      title = "Test Generation",
      level = "error",
      timeout = 2000,
    })
    return
  end

  local missing_lines = file_coverage.missing_lines or {}
  if #missing_lines == 0 then
    require("snacks").notify("🎉 This file has complete coverage!\nNo missing lines to test", {
      title = "Test Generation",
      timeout = 2000,
    })
    return
  end

  -- Show missing lines and let user choose
  local missing_summary = {}
  for i, line_num in ipairs(missing_lines) do
    if i <= 5 then -- Show first 5 missing lines
      local line_content = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1] or ""
      table.insert(missing_summary, string.format("Line %d: %s", line_num, line_content:match("^%s*(.-)%s*$")))
    end
  end

  if #missing_lines > 5 then
    table.insert(missing_summary, string.format("... and %d more lines", #missing_lines - 5))
  end

  require("snacks").notify(
    "🎯 Missing coverage found:\n"
      .. table.concat(missing_summary, "\n")
      .. "\n\nJump to a missing line and use <leader>tn",
    {
      title = "Missing Coverage",
      timeout = 2000,
    }
  )

  -- Jump to first missing line
  if #missing_lines > 0 then
    vim.api.nvim_win_set_cursor(0, { missing_lines[1], 0 })
  end
end

-- SETUP FUNCTION
function M.setup()
  setup_signs()
  setup_highlights()

  -- Auto-load coverage for Python files
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.py",
    callback = function()
      vim.defer_fn(function()
        if find_coverage_file() and not coverage_visible then
          M.coverage.load()
        elseif coverage_visible then
          -- Re-place signs for this buffer
          place_signs_for_buffer(vim.api.nvim_get_current_buf())
        end
      end, 100)
    end,
  })
end

return M
