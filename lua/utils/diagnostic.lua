-- Diagnostic utility functions and configuration

-- Configure diagnostics
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    source = "if_many",
    format = function(diagnostic)
      if diagnostic.message and diagnostic.message:lower():match("trailing") then
        return nil
      end

      local key = string.format("%d:%d:%s",
        diagnostic.lnum,
        diagnostic.col,
        diagnostic.message
      )

      if not _G.diagnostic_tracker then
        _G.diagnostic_tracker = {
          seen = {},
          buffer_generation = {}
        }
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local buffer_key = bufnr .. ":" .. key

      if _G.diagnostic_tracker.seen[buffer_key] then
        return nil
      end

      _G.diagnostic_tracker.seen[buffer_key] = true
      return diagnostic.message
    end,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "x",
      [vim.diagnostic.severity.WARN] = "x",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
})

-- Diagnostic utility functions
local M = {}

function M.copy_diagnostic_under_cursor()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })

  if #diagnostics == 0 then
    print("No diagnostic at cursor")
    return
  end

  local message = diagnostics[1].message
  vim.fn.setreg('+', message)
  vim.fn.setreg('"', message)
  print("Copied: " .. (message:len() > 50 and message:sub(1, 50) .. "..." or message))
end

function M.copy_all_diagnostics_on_line()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })

  if #diagnostics == 0 then
    print("No diagnostics on current line")
    return
  end

  local messages = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, diagnostic.message)
  end

  local combined = table.concat(messages, ' | ')
  vim.fn.setreg('+', combined)
  vim.fn.setreg('"', combined)
  print("Copied " .. #diagnostics .. " diagnostic(s)")
end

function M.copy_messages()
  local messages = vim.fn.execute('messages')
  vim.fn.setreg('+', messages)
  vim.fn.setreg('"', messages)
  print("Messages copied to clipboard")
end

-- Set up keymaps for diagnostic functions
vim.keymap.set('n', '<leader>cd', M.copy_diagnostic_under_cursor, { desc = 'Copy diagnostic under cursor' })
vim.keymap.set('n', '<leader>cD', M.copy_all_diagnostics_on_line, { desc = 'Copy all diagnostics on line' })
vim.keymap.set('n', '<leader>cm', M.copy_messages, { desc = 'Copy messages to clipboard' })

return M
