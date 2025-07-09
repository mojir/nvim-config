local config = require("session.config")
local data = require("session.data")
local tracking = require("session.tracking")

local M = {}

-- Helper function to format session name back to readable path
local function format_session_name(session_name)
  -- Convert underscores back to path separators
  local path = session_name:gsub("_", "/")
  
  -- Add leading slash if it doesn't start with one
  if not path:match("^/") then
    path = "/" .. path
  end
  
  -- Replace home directory with ~
  local home = vim.fn.expand("~")
  if path:sub(1, #home) == home then
    path = "~" .. path:sub(#home + 1)
  end
  
  return path
end

-- Helper function to get the timestamp of a session
local function get_session_timestamp(session_dir)
  local vim_file = session_dir .. "session.vim"
  local json_file = session_dir .. "data.json"
  
  local vim_time = vim.fn.getftime(vim_file)
  local json_time = vim.fn.getftime(json_file)
  
  -- Use the newest file timestamp, fallback to 0 if neither exists
  local timestamp = math.max(vim_time or 0, json_time or 0)
  return timestamp
end

-- Helper function to format timestamp as ISO date
local function format_timestamp(timestamp)
  if timestamp == 0 then
    return "unknown"
  end
  
  -- Format as ISO date (YYYY-MM-DD HH:MM)
  return os.date("%Y-%m-%d %H:%M", timestamp)
end

-- Clear all global marks (used when switching sessions)
local function clear_global_marks()
  for i = 65, 90 do
    local mark = string.char(i)
    vim.cmd("silent! delmarks " .. mark)
  end
end

local function save_session()
  config.ensure_session_dir()
  
  -- Close problematic buffers before saving
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buftype = vim.bo[buf].buftype
      local name = vim.api.nvim_buf_get_name(buf)
      
      if buftype == "terminal" or buftype == "help" or buftype == "quickfix" then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      elseif name ~= "" and vim.fn.filereadable(name) == 0 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
  
  -- Close nvim-tree before saving
  if pcall(require, "nvim-tree.api") then
    require("nvim-tree.api").tree.close()
  end
  
  -- Save enhanced session data
  data.save_session_data()
  
  -- Save vim session
  local session_file = config.get_session_file()
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
  
  print("Session saved: " .. vim.fn.fnamemodify(session_file, ":t"))
end

local function load_session()
  local session_file = config.get_session_file()
  local data_file = config.get_data_file()
  
  if vim.fn.filereadable(session_file) == 1 then
    -- Load existing session
    vim.cmd("source " .. vim.fn.fnameescape(session_file))
    
    -- Load enhanced session data
    vim.defer_fn(function()
      local data_loaded = data.load_session_data()
      
      -- If .json file doesn't exist or failed to load, create it
      if not data_loaded then
        data.save_session_data()
      end
      
      -- Change to original directory after loading session data
      if data_loaded then
        local session_data = data.get_last_loaded_data()
        if session_data and session_data.original_cwd and vim.fn.isdirectory(session_data.original_cwd) == 1 then
          vim.cmd("cd " .. vim.fn.fnameescape(session_data.original_cwd))
        end
      end
      
      -- Reload nvim-tree after session load
      if pcall(require, "nvim-tree.api") then
        require("nvim-tree.api").tree.reload()
      end
    end, 100)
  else
    -- Create new session immediately
    save_session()
  end
end

function M.switch_to_session(target_session_name)
  -- Save current session before switching
  save_session()
  
  -- Clear current session
  vim.cmd("silent! %bdelete!")
  clear_global_marks()
  tracking.clear_access_history()
  
  -- Load target session
  local session_file = config.session_dir .. target_session_name .. "/session.vim"
  vim.cmd("source " .. vim.fn.fnameescape(session_file))
  
  -- Load enhanced session data
  vim.defer_fn(function()
    local data_loaded = data.load_session_data()
    
    -- Change to original directory after loading session data
    if data_loaded then
      local session_data = data.get_last_loaded_data()
      if session_data and session_data.original_cwd and vim.fn.isdirectory(session_data.original_cwd) == 1 then
        vim.cmd("cd " .. vim.fn.fnameescape(session_data.original_cwd))
      end
    end
    
    print("Switched to session: " .. target_session_name)
  end, 100)
end

function M.delete_session()
  local session_dir = config.get_session_dir()
  
  if vim.fn.isdirectory(session_dir) == 1 then
    vim.fn.delete(session_dir, "rf")
    print("Session deleted: " .. config.get_session_name())
  else
    print("No session to delete")
  end
end

function M.get_sorted_sessions_with_display()
  local session_dirs = vim.fn.glob(config.session_dir .. "*/", false, true)
  if #session_dirs == 0 then
    return {}
  end
  
  -- Sort sessions by last modified time (newest first)
  local sessions_with_time = {}
  for _, session_dir in ipairs(session_dirs) do
    local name = vim.fn.fnamemodify(session_dir, ":h:t")
    local timestamp = get_session_timestamp(session_dir)
    table.insert(sessions_with_time, { name = name, timestamp = timestamp, dir = session_dir })
  end
  
  table.sort(sessions_with_time, function(a, b)
    return a.timestamp > b.timestamp
  end)
  
  -- Format for display
  local session_items = {}
  for _, session in ipairs(sessions_with_time) do
    local timestamp_str = format_timestamp(session.timestamp)
    local formatted_name = format_session_name(session.name)
    
    -- Add marker for current session
    local current_session = config.get_session_name()
    local marker = (session.name == current_session) and "* " or "  "
    
    table.insert(session_items, {
      name = session.name,  -- Keep original name for switching
      display = marker .. formatted_name .. " (" .. timestamp_str .. ")",
      dir = session.dir,
    })
  end
  
  return session_items
end

function M.list_sessions()
  local session_items = M.get_sorted_sessions_with_display()
  if #session_items == 0 then
    print("No sessions found")
    return {}
  end
  
  print("Available sessions (sorted by last used):")
  for _, session in ipairs(session_items) do
    print("  " .. session.display)
  end
  
  local result = {}
  for _, session in ipairs(session_items) do
    table.insert(result, session.name)
  end
  return result
end

-- Public API - only functions that should be called from outside
M.init = function()
  -- Setup autocmds to call internal functions
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("SimpleSessionLoad", { clear = true }),
    callback = function()
      if vim.fn.argc() == 0 then
        vim.defer_fn(function()
          load_session()
        end, 50)
      end
    end,
  })
  
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("SimpleSession", { clear = true }),
    callback = function()
      if vim.fn.argc() == 0 then
        save_session()
      end
    end,
  })
end

return M
