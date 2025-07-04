local M = {}

-- State management
local state = {
  current_program = "",
  last_result = "",
  current_file = "",
  last_explicit_file = nil, -- Track explicitly saved files for reopening
  editor_buf = nil,
  editor_win = nil,
  result_buf = nil,
  result_win = nil,
  original_cursor_pos = nil,
  original_win = nil,
  autocmd_group = nil,
  initialized = false,
}

function M.get()
  return state
end

function M.set(key, value)
  state[key] = value
end

function M.reset()
  state.current_program = ""
  state.last_result = ""
  state.editor_buf = nil
  state.editor_win = nil
  state.result_buf = nil
  state.result_win = nil
  state.original_cursor_pos = nil
  state.original_win = nil
  -- Note: Don't reset current_file and last_explicit_file on editor close
  -- They should persist between sessions
end

function M.is_initialized()
  return state.initialized
end

function M.set_initialized(value)
  state.initialized = value
end

function M.get_autocmd_group()
  return state.autocmd_group
end

function M.set_autocmd_group(group)
  state.autocmd_group = group
end

-- Persistence functions for session data
function M.save_session_data()
  local session_file = vim.fn.stdpath("data") .. "/lits-session.json"
  local session_data = {
    current_file = state.current_file,
    last_explicit_file = state.last_explicit_file,
  }
  
  local ok, encoded = pcall(vim.fn.json_encode, session_data)
  if ok then
    local file = io.open(session_file, "w")
    if file then
      file:write(encoded)
      file:close()
    end
  end
end

function M.load_session_data()
  local session_file = vim.fn.stdpath("data") .. "/lits-session.json"
  local file = io.open(session_file, "r")
  
  if file then
    local content = file:read("*a")
    file:close()
    
    local ok, session_data = pcall(vim.fn.json_decode, content)
    if ok and session_data then
      state.current_file = session_data.current_file or ""
      state.last_explicit_file = session_data.last_explicit_file
    end
  end
end

return M
