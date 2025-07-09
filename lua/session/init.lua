local config = require("session.config")
local core = require("session.core")
local data = require("session.data")
local tracking = require("session.tracking")
local picker = require("session.picker")

local M = {}

function M.setup()
  -- Ensure session directory exists
  config.ensure_session_dir()
  
  -- Configure session options
  vim.o.sessionoptions = config.session_options
  
  -- Setup real-time buffer tracking
  tracking.setup_tracking()
  
  -- Initialize core functionality
  core.init()
  
  -- Auto-save session data when marks are modified
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("SessionData", { clear = true }),
    callback = function()
      -- Only auto-save data, not the full session
      data.save_session_data()
    end,
  })
  
  -- Commands
  vim.api.nvim_create_user_command("SessionPick", picker.session_picker, { desc = "Pick session (Telescope)" })
  
  -- Keymaps
  vim.keymap.set("n", "<leader>sp", picker.session_picker, { desc = "Pick session (Telescope)" })
end

-- Export only the public API
M.switch_to_session = core.switch_to_session
M.get_sorted_sessions_with_display = core.get_sorted_sessions_with_display
M.session_picker = picker.session_picker

return M
