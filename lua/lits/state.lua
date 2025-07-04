-- lua/lits/state.lua
local M = {}

-- State management
local state = {
  current_program = "",
  last_result = "",
  current_file = "",
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

return M
