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

-- Public API
function M.can_acquire_lock(directory)
  if not directory then
    return false
  end
  
  local lock_dir = config.session_dir .. vim.fn.substitute(directory, "[/\\:]", "_", "g") .. "/"
  local lock_file = lock_dir .. ".session.lock"
  
  -- Check if lock exists and is active
  if vim.fn.filereadable(lock_file) == 1 then
    local lock_content = vim.fn.readfile(lock_file)
    if #lock_content >= 1 then
      local locked_pid = tonumber(lock_content[1])
      
      if locked_pid and is_process_running(locked_pid) then
        return false  -- Session is actively locked
      end
    end
  end
  
  return true  -- Can acquire lock
end

function M.acquire_lock(directory)
  if not directory then
    return false
  end
  
  local lock_dir = config.session_dir .. vim.fn.substitute(directory, "[/\\:]", "_", "g") .. "/"
  vim.fn.mkdir(lock_dir, "p")
  
  session_lock_file = lock_dir .. ".session.lock"
  
  -- Check if lock exists and is active
  if vim.fn.filereadable(session_lock_file) == 1 then
    local lock_content = vim.fn.readfile(session_lock_file)
    if #lock_content >= 1 then
      local locked_pid = tonumber(lock_content[1])
      
      if locked_pid and is_process_running(locked_pid) then
        return false  -- Session is actively locked
      end
    end
  end
  
  -- Create lock file with current PID
  local lock_content = tostring(vim.fn.getpid()) .. "\n" .. os.time()
  vim.fn.writefile(vim.split(lock_content, "\n"), session_lock_file)
  
  return true
end

function M.release_lock()
  if session_lock_file and vim.fn.filereadable(session_lock_file) == 1 then
    vim.fn.delete(session_lock_file)
    session_lock_file = nil
    return true
  end
  return false  -- No lock to release
end

function M.has_lock()
  return session_lock_file ~= nil
end

return M
