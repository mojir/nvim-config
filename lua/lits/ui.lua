-- lua/lits/ui.lua
local config = require("lits.config")
local state = require("lits.state")
local utils = require("lits.utils")

local M = {}

function M.cleanup_state()
  local current_state = state.get()
  
  -- Clear autocmds
  if current_state.autocmd_group then
    pcall(vim.api.nvim_del_augroup_by_id, current_state.autocmd_group)
    state.set("autocmd_group", nil)
  end

  -- Close windows and clean buffers
  if current_state.result_win and vim.api.nvim_win_is_valid(current_state.result_win) then
    pcall(vim.api.nvim_win_close, current_state.result_win, true)
  end
  if current_state.result_buf and vim.api.nvim_buf_is_valid(current_state.result_buf) then
    pcall(vim.api.nvim_buf_delete, current_state.result_buf, { force = true })
  end

  if current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win) then
    pcall(vim.api.nvim_win_close, current_state.editor_win, true)
  end
  if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
    pcall(vim.api.nvim_buf_delete, current_state.editor_buf, { force = true })
  end

  -- Reset state
  state.reset()
end

function M.close_result_popup()
  local current_state = state.get()
  
  if current_state.result_win and vim.api.nvim_win_is_valid(current_state.result_win) then
    pcall(vim.api.nvim_win_close, current_state.result_win, true)
    state.set("result_win", nil)
  end
  if current_state.result_buf and vim.api.nvim_buf_is_valid(current_state.result_buf) then
    pcall(vim.api.nvim_buf_delete, current_state.result_buf, { force = true })
    state.set("result_buf", nil)
  end

  -- Return focus to editor window if it exists
  if current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win) then
    vim.api.nvim_set_current_win(current_state.editor_win)
  end
end

function M.close_editor()
  M.close_result_popup()
  local current_state = state.get()

  if current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win) then
    -- Auto-save on close if content changed
    if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
      local lines = vim.api.nvim_buf_get_lines(current_state.editor_buf, 0, -1, false)
      local content = table.concat(lines, "\n")
      if content ~= current_state.current_program then
        utils.save_program(content, current_state.current_file)
        state.set("current_program", content)
      end
    end

    pcall(vim.api.nvim_win_close, current_state.editor_win, true)
    state.set("editor_win", nil)
  end

  if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
    pcall(vim.api.nvim_buf_delete, current_state.editor_buf, { force = true })
    state.set("editor_buf", nil)
  end
end

function M.close_editor_and_return_to_original()
  M.close_editor()
  local current_state = state.get()

  -- Restore original window and cursor position
  if current_state.original_win and vim.api.nvim_win_is_valid(current_state.original_win) then
    vim.api.nvim_set_current_win(current_state.original_win)
    if current_state.original_cursor_pos then
      pcall(vim.api.nvim_win_set_cursor, current_state.original_win, current_state.original_cursor_pos)
    end
  end
end

return M
