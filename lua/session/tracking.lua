local config = require("session.config")

local M = {}

-- Buffer access tracking
local access_history = {}

function M.track_buffer_access(bufname)
  if not bufname or bufname == "" then
    return
  end
  
  -- Don't track special buffers
  local buftype = vim.bo.buftype
  if buftype ~= "" then
    return
  end
  
  -- Don't track non-file buffers
  if not vim.fn.filereadable(bufname) then
    return
  end
  
  -- Remove if already in history
  for i, name in ipairs(access_history) do
    if name == bufname then
      table.remove(access_history, i)
      break
    end
  end
  
  -- Add to front
  table.insert(access_history, 1, bufname)
  
  -- Trim if too long
  if #access_history > config.HISTORY_LIMIT then
    access_history[config.HISTORY_LIMIT + 1] = nil
  end
end

function M.get_access_history()
  return vim.deepcopy(access_history)
end

function M.clear_access_history()
  access_history = {}
end

function M.setup_tracking()
  -- Track buffer access in real-time
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("SessionTracking", { clear = true }),
    callback = function()
      local bufname = vim.api.nvim_buf_get_name(0)
      M.track_buffer_access(bufname)
    end,
  })
end

return M
