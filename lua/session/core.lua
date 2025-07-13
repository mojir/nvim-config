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
  -- Handle session save conflicts (auto-skip if locked)
  local save_result = lock.handle_session_save()
  
  if save_result == false then
    return -- Skip save due to lock conflict
  end
  
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

  -- Handle session load conflicts (simplified - no read-only)
  local load_result = lock.handle_session_load(session_locked_to_directory)

  if load_result == false then
    print("Session loading cancelled")
    return
  end
  -- load_result == true means normal load with acquired lock

  local session_file = config.get_session_file()

  if vim.fn.filereadable(session_file) == 1 then
    -- Load existing session
    vim.cmd("source " .. vim.fn.fnameescape(session_file))
    session_loaded = true

    -- Load enhanced session data and clear navigation state
    vim.defer_fn(function()
      local data_loaded = data.load_session_data()

      -- If .json file doesn't exist or failed to load, create it
      if not data_loaded then
        data.save_session_data()
      end

      -- Clear navigation state after session restoration
      vim.cmd("silent! clearjumps")
      vim.cmd("silent! delmarks!")

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

  -- Clear current session state
  vim.cmd("silent! %bdelete!")
  tracking.clear_access_history()

  -- Clear navigation state immediately for clean slate
  vim.cmd("silent! clearjumps")

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

  -- Handle lock acquisition for target session (simplified)
  local load_result = lock.handle_session_load(session_locked_to_directory)

  if load_result == false then
    vim.schedule(function()
      print("Cannot switch: session loading cancelled")
    end)
    session_loaded = false
    return
  end

  session_loaded = true

  -- Load target session
  local session_file = config.session_dir .. target_session_name .. "/session.vim"
  vim.cmd("source " .. vim.fn.fnameescape(session_file))

  -- Load session data and clear navigation state again after session loads
  vim.defer_fn(function()
    local data_loaded = data.load_session_data()

    -- Clear navigation state after session restoration (for safety)
    vim.cmd("silent! clearjumps")

    -- Change to target directory
    if data_loaded then
      local session_data = data.get_last_loaded_data()
      if session_data and session_data.original_cwd and vim.fn.isdirectory(session_data.original_cwd) == 1 then
        vim.cmd("cd " .. vim.fn.fnameescape(session_data.original_cwd))
      end
    else
      -- Fallback to target path if no session data
      vim.cmd("cd " .. vim.fn.fnameescape(target_path))
    end

    -- Reload nvim-tree for new session
    if pcall(require, "nvim-tree.api") then
      require("nvim-tree.api").tree.reload()
    end
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
      print("=== SESSION DEBUG START ===")
      print("Current working directory at VimEnter:", vim.fn.getcwd())
      print("Current argc():", vim.fn.argc())
      
      -- Use original args if available, fallback to current
      local original_args = _G.original_nvim_args
      local use_cwd = original_args and original_args.cwd or vim.fn.getcwd()
      local use_argc = original_args and original_args.argc or vim.fn.argc()
      local use_argv = original_args and original_args.argv or {}
      
      print("ORIGINAL working directory:", use_cwd)
      print("ORIGINAL argc:", use_argc)
      
      -- Print original arguments
      for i = 0, use_argc - 1 do
        local arg = use_argv[i]
        print("ORIGINAL argv[" .. i .. "]:", vim.inspect(arg))
      end
      
      local should_load_session = false
      local target_directory = nil

      if use_argc == 0 then
        print("No arguments case")
        should_load_session = true
        target_directory = use_cwd
        print("Target directory:", target_directory)
      else
        print("Has arguments case")
        -- Check each original argument
        for i = 0, use_argc - 1 do
          local arg = use_argv[i]
          
          if type(arg) == "table" then
            arg = arg[1]
          end
          
          if arg and type(arg) == "string" then
            print("Processing original arg:", arg)
            
            -- Resolve relative paths against original cwd
            local resolved_path
            if arg == "." then
              resolved_path = use_cwd
            elseif arg:match("^/") then
              -- Already absolute
              resolved_path = arg
            else
              -- Relative path
              resolved_path = use_cwd .. "/" .. arg
            end
            
            print("Resolved path:", resolved_path)
            print("Is directory?", vim.fn.isdirectory(resolved_path) == 1)
            print("Is file?", vim.fn.filereadable(resolved_path) == 1)
            
            if vim.fn.isdirectory(resolved_path) == 1 then
              print("Found directory argument:", resolved_path)
              should_load_session = true
              target_directory = vim.fn.fnamemodify(resolved_path, ":p")
              print("Resolved target directory:", target_directory)
              break
            elseif vim.fn.filereadable(resolved_path) == 1 then
              print("Found file argument:", resolved_path)
              target_directory = vim.fn.fnamemodify(resolved_path, ":p:h")
              should_load_session = false
              print("File's directory:", target_directory)
              break
            else
              print("Argument is neither existing file nor directory:", resolved_path)
            end
          end
        end
        
        if not target_directory then
          print("No valid files/dirs found, using first argument as potential directory")
          local first_arg = use_argv[0]
          if type(first_arg) == "table" then
            first_arg = first_arg[1]
          end
          
          if first_arg and type(first_arg) == "string" then
            if first_arg == "." then
              target_directory = use_cwd
            else
              target_directory = use_cwd .. "/" .. first_arg
            end
            target_directory = vim.fn.fnamemodify(target_directory, ":p")
            should_load_session = true
            print("Fallback target directory:", target_directory)
          end
        end
      end

      print("Final decision:")
      print("  should_load_session:", should_load_session)
      print("  target_directory:", target_directory)
      
      if should_load_session and target_directory then
        print("About to change directory to:", target_directory)
        
        if vim.fn.isdirectory(target_directory) == 1 then
          vim.cmd("cd " .. vim.fn.fnameescape(target_directory))
          print("Changed directory to:", vim.fn.getcwd())
        else
          print("Target directory doesn't exist, creating:", target_directory)
          vim.fn.mkdir(target_directory, "p")
          vim.cmd("cd " .. vim.fn.fnameescape(target_directory))
          print("Created and changed to:", vim.fn.getcwd())
        end
        
        print("About to load session...")
        vim.defer_fn(function()
          print("Loading session for directory:", vim.fn.getcwd())
          print("Session name will be:", config.get_session_name())
          print("Session directory will be:", config.get_session_dir())
          load_session()
        end, 50)
      else
        print("Not loading session")
      end
      
      print("=== SESSION DEBUG END ===")
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
