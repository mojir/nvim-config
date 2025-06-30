return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local filename_config = {
        "filename",
        path = 1, -- Show relative path
        file_status = true, -- Shorten path if longer than 40 chars
        symbols = {
          modified = "●",
          readonly = "🔒",
          unnamed = "[No Name]",
        },
      }

      -- Function to get selection statistics
      local function selection_stats()
        local mode = vim.fn.mode()

        -- Only show in visual modes, but skip block mode entirely
        if not mode:match("[vV]") or mode == "\22" then
          return ""
        end

        -- Get selection bounds
        local start_pos = vim.fn.getpos("v")
        local end_pos = vim.fn.getpos(".")

        -- Ensure start is before end
        if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
          start_pos, end_pos = end_pos, start_pos
        end

        local lines = end_pos[2] - start_pos[2] + 1
        local chars = 0
        local words = 0

        if mode == "V" then
          -- Visual line mode - select entire lines
          local selected_text = {}
          for i = start_pos[2], end_pos[2] do
            local line = vim.fn.getline(i)
            table.insert(selected_text, line)
          end

          local text = table.concat(selected_text, "\n")
          chars = vim.fn.strlen(text)

          -- Count words
          for _ in text:gmatch("%S+") do
            words = words + 1
          end
        elseif mode == "\22" then
          -- Visual block mode - only show line count
          -- Word and character counts are unreliable due to virtual positions
        else
          -- Character-wise visual mode (v)
          local selected_text = {}
          for i = start_pos[2], end_pos[2] do
            local line = vim.fn.getline(i)
            if i == start_pos[2] and i == end_pos[2] then
              -- Single line selection
              line = line:sub(start_pos[3], end_pos[3])
            elseif i == start_pos[2] then
              -- First line
              line = line:sub(start_pos[3])
            elseif i == end_pos[2] then
              -- Last line
              line = line:sub(1, end_pos[3])
            end
            table.insert(selected_text, line)
          end

          local text = table.concat(selected_text, "\n")
          chars = vim.fn.strlen(text)

          -- Count words
          for _ in text:gmatch("%S+") do
            words = words + 1
          end
        end

        -- Format output without mode indicators, using lowercase
        return string.format("l:%d w:%d c:%d", lines, words, chars)
      end

      require("lualine").setup({
        options = {
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { filename_config },
          lualine_x = {
            selection_stats, -- Add our custom selection stats
            "encoding",
            "fileformat",
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { filename_config },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
      })
    end,
  },
}
