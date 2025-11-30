return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.component_separators = { left = "│", right = "│" }

    local function registers()
      local cols = vim.o.columns
      if cols < 120 then
        return ""
      end

      local max_regs = math.min(9, math.floor((cols - 120) / 25) + 3)
      local char_limit = cols > 180 and 15 or cols > 150 and 12 or 10

      local regs = {}
      for i = 1, max_regs do
        local reg = vim.fn.getreg(tostring(i))
        if reg and reg ~= "" then
          local display = reg:gsub("\n", " "):gsub("%s+", " "):sub(1, char_limit)
          if #reg > char_limit then
            display = display .. "…"
          end
          table.insert(regs, string.format("%d:%s", i, display))
        end
      end

      return #regs > 0 and table.concat(regs, " │ ") or ""
    end

    table.insert(opts.sections.lualine_x, 1, {
      registers,
      icon = "",
      color = { fg = "#7aa2f7" },
      padding = { left = 2, right = 2 },
    })
  end,
}
