local config = require("session.config")
local data = require("session.data")
local tracking = require("session.tracking")
local lock = require("session.lock") -- Add this

local M = {}

-- Session state tracking
local session_loaded = false
local session_locked_to_directory = nil

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

-- Clear all global marks (used when switching sessions)
local function clear_global_marks()
  for i = 65, 90 do
    local mark = string.char(i)
    vim.cmd("silent! delmarks " .. mark)
  end
end

local function save_session()
  -- Temporarily change to locked directory for all session operations
  local original_cwd = vim.fn.getcwd()
  local target_dir = session_locked_to_directory or original_cwd

  vim.cmd("cd " .. vim.fn.fnameescape(target_dir))

  -- Now all existing code works unchanged because cwd is correct
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

  -- Save enhanced session data (uses config.get_data_file() which now works)
  data.save_session_data()

  -- Save vim session (uses config.get_session_file() which now works)
  local session_file = config.get_session_file()
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))

  -- Restore original directory
  vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))

  print("Session saved: " .. vim.fn.fnamemodify(session_file, ":t"))
end

local function load_session()
  -- Lock to current directory when session loads
  session_locked_to_directory = vim.fn.getcwd()

  if not lock.acquire_lock(session_locked_to_directory) then
    print("Another Neovim instance is using this session. Opening without session.")
    return
  end

  local session_file = config.get_session_file()

  if vim.fn.filereadable(session_file) == 1 then
    -- Load existing session
    vim.cmd("source " .. vim.fn.fnameescape(session_file))
    session_loaded = true

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
    session_loaded = true
  end
end

function M.get_current_session_info()
  return {
    loaded = session_loaded,
    directory = session_locked_to_directory,
    name = session_locked_to_directory and vim.fn.substitute(session_locked_to_directory, "[/\\:]", "_", "g") or nil,
  }
end

function M.switch_to_session(target_session_name)
  -- Only save if we actually have a session loaded
  if session_loaded then
    save_session()
    lock.release_lock() -- Release old session's lock
  end

  -- Clear current session
  vim.cmd("silent! %bdelete!")
  clear_global_marks()
  tracking.clear_access_history()

  -- Convert session name back to directory path
  local target_path = target_session_name:gsub("_", "/")

  -- Handle different path formats
  if target_path:match("^home/") then
    target_path = "/" .. target_path
  elseif not target_path:match("^/") and not target_path:match("^~") then
    target_path = "/" .. target_path
  end

  -- Expand ~ to home directory if needed
  if target_path:sub(1, 2) == "~/" then
    target_path = vim.fn.expand("~") .. target_path:sub(2)
  elseif target_path == "~" then
    target_path = vim.fn.expand("~")
  end

  -- Update the locked directory and try to acquire lock for new session
  session_locked_to_directory = target_path

if not lock.acquire_lock(session_locked_to_directory) then
  vim.schedule(function()
    print("Cannot switch: target session is locked by another Neovim instance")
  end)
  session_loaded = false
  return
end

  session_loaded = true

  -- Load target session
  local session_file = config.session_dir .. target_session_name .. "/session.vim"
  vim.cmd("source " .. vim.fn.fnameescape(session_file))

  -- ... rest of existing load logic
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
    table.insert(sessions_with_time, {
      name = name,
      timestamp = timestamp,
      dir = session_dir,
    })
  end

  table.sort(sessions_with_time, function(a, b)
    local current_session = config.get_session_name()

    -- Current session always comes first (appears at bottom in telescope)
    if a.name == current_session then
      return true
    elseif b.name == current_session then
      return false
    else
      -- For non-current sessions, sort by timestamp (newest first)
      return a.timestamp > b.timestamp
    end
  end)

  -- Return raw session data - let picker handle formatting
  local session_items = {}
  local current_session = config.get_session_name()

  for _, session in ipairs(sessions_with_time) do
    table.insert(session_items, {
      name = session.name,
      dir = session.dir,
      timestamp = session.timestamp,
      is_current = (session.name == current_session),
    })
  end

  return session_items
end

-- Public API - only functions that should be called from outside
M.init = function()
  -- Setup autocmds to call internal functions
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("SimpleSessionLoad", { clear = true }),
    callback = function()
      local should_load_session = false

      if vim.fn.argc() == 0 then
        -- No arguments - always load session
        should_load_session = true
      elseif vim.fn.argc() == 1 then
        -- One argument - check if it's a directory
        local arg = vim.v.argv[2] -- argv[1] is nvim itself, argv[2] is first argument

        if arg and vim.fn.isdirectory(arg) == 1 then
          should_load_session = true
          -- Change to the directory first
          vim.cmd("cd " .. vim.fn.fnameescape(arg))
        end
      end

      if should_load_session then
        vim.defer_fn(function()
          load_session()
        end, 50)
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("SimpleSession", { clear = true }),
    callback = function()
      if session_loaded then
        save_session()
        lock.release_lock() -- Only release if we had a session
      end
    end,
  })
end

return M
