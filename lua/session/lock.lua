local config = require("session.config")

local M = {}

-- Module state
local session_lock_file = nil

-- Helper function to check if PID is still running
local function is_process_running(pid)
  local handle = io.popen("kill -0 " .. pid .. " 2>/dev/null; echo $?")
  if handle then
    local result = handle:read("*line")
    handle:close()
    return result == "0"
  end
  return false
end

-- Get lock info if it exists
local function get_lock_info(directory)
  local lock_dir = config.session_dir .. vim.fn.substitute(directory, "[/\\:]", "_", "g") .. "/"
  local lock_file = lock_dir .. ".session.lock"
  
  if vim.fn.filereadable(lock_file) == 1 then
    local lock_content = vim.fn.readfile(lock_file)
    if #lock_content >= 2 then
      local locked_pid = tonumber(lock_content[1])
      local lock_time = tonumber(lock_content[2])
      
      if locked_pid then
        return {
          pid = locked_pid,
          timestamp = lock_time,
          file = lock_file,
          is_running = is_process_running(locked_pid)
        }
      end
    end
  end
  
  return nil
end

-- Enhanced session loading with user choice (simplified - no read-only)
function M.handle_session_load(directory)
  local lock_info = get_lock_info(directory)
  
  if not lock_info then
    -- No lock, proceed normally
    return M.acquire_lock(directory)
  end
  
  -- Check if this is our own PID (shouldn't happen, but clean up if so)
  if lock_info.pid == vim.fn.getpid() then
    vim.fn.delete(lock_info.file)
    return M.acquire_lock(directory)
  end
  
  if lock_info.is_running then
    -- Active lock from different process - simple choice
    local lock_age = os.time() - (lock_info.timestamp or 0)
    local hours = math.floor(lock_age / 3600)
    local minutes = math.floor((lock_age % 3600) / 60)
    
    local message = string.format(
      "Session is locked by another Neovim instance (PID: %d)\n" ..
      "Lock age: %dh %dm\n\n" ..
      "What would you like to do?",
      lock_info.pid, hours, minutes
    )
    
    local choice = vim.fn.confirm(message, 
      "&Force takeover\n" .. 
      "&Cancel", 2)
    
    if choice == 1 then
      vim.fn.delete(lock_info.file)
      return M.acquire_lock(directory)
    else
      return false
    end
  else
    -- Stale lock - automatically clean up and continue
    vim.fn.delete(lock_info.file)
    print("Cleaned up stale session lock (PID " .. lock_info.pid .. " no longer running)")
    return M.acquire_lock(directory)
  end
end

-- Simplified session saving (auto-skip if locked)
function M.handle_session_save()
  local current_dir = vim.fn.getcwd()
  local lock_info = get_lock_info(current_dir)
  
  -- Always check if someone else has an active lock
  if lock_info and lock_info.is_running and lock_info.pid ~= vim.fn.getpid() then
    print("Session save skipped (locked by another instance)")
    return false
  end
  
  return true
end

-- Check if we can acquire lock (for picker)
function M.can_acquire_lock(directory)
  local lock_info = get_lock_info(directory)
  return not lock_info or not lock_info.is_running
end

-- Acquire lock for directory
function M.acquire_lock(directory)
  if not directory then
    return false
  end
  
  local lock_dir = config.session_dir .. vim.fn.substitute(directory, "[/\\:]", "_", "g") .. "/"
  vim.fn.mkdir(lock_dir, "p")
  
  session_lock_file = lock_dir .. ".session.lock"
  
  local lock_info = get_lock_info(directory)
  if lock_info and lock_info.is_running then
    return false
  end
  
  if lock_info then
    vim.fn.delete(lock_info.file)
  end
  
  local lock_content = tostring(vim.fn.getpid()) .. "\n" .. os.time()
  vim.fn.writefile(vim.split(lock_content, "\n"), session_lock_file)
  
  return true
end

-- Release our lock (with ownership verification)
function M.release_lock()
  if session_lock_file and vim.fn.filereadable(session_lock_file) == 1 then
    -- Verify this lock actually belongs to us before deleting
    local lock_content = vim.fn.readfile(session_lock_file)
    if #lock_content >= 1 then
      local locked_pid = tonumber(lock_content[1])
      if locked_pid == vim.fn.getpid() then
        -- It's our lock, safe to delete
        vim.fn.delete(session_lock_file)
        session_lock_file = nil
        return true
      else
        -- Someone else's lock, don't delete it
        session_lock_file = nil
        return false
      end
    end
  end
  session_lock_file = nil
  return false
end

-- Check if we have a lock
function M.has_lock()
  return session_lock_file ~= nil
end

return M
