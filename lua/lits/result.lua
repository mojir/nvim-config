-- lua/lits/result.lua
local config = require("lits.config")
local state = require("lits.state")
local utils = require("lits.utils")
local ui = require("lits.ui")

local M = {}

function M.create_popup(result_text, show_insert_option)
  ui.close_result_popup()

  local result_lines = vim.split(result_text, "\n")
  local width, height = utils.calculate_window_size(result_text)

  -- Create buffer
  local result_buf = vim.api.nvim_create_buf(false, true)
  state.set("result_buf", result_buf)
  
  vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, result_lines)
  vim.bo[result_buf].readonly = true
  vim.bo[result_buf].modifiable = false
  vim.bo[result_buf].filetype = "text"

  -- Add help text if insert option is available
  if show_insert_option then
    vim.bo[result_buf].modifiable = true
    vim.api.nvim_buf_set_lines(result_buf, -1, -1, false, {
      "",
      "(i)nsert  (y)ank  (q)uit",
    })
    vim.bo[result_buf].modifiable = false
  end

  -- Create window
  local result_win = vim.api.nvim_open_win(result_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = config.get().popup.border,
    title = " Lits Result ",
    title_pos = "center",
  })
  state.set("result_win", result_win)

  -- Ensure we're in normal mode and focused on our buffer
  vim.cmd("stopinsert")
  vim.api.nvim_set_current_buf(result_buf)

  -- Set up keymaps
  local opts = { buffer = result_buf, noremap = true, silent = true, nowait = true }

  -- QUIT/CANCEL options - return to editor
  vim.keymap.set("n", "q", ui.close_result_popup, opts)
  vim.keymap.set("n", "<Esc>", ui.close_result_popup, opts)

  if show_insert_option then
    -- INSERT option - insert result at original position
    vim.keymap.set("n", "i", function()
      ui.close_result_popup()
      ui.close_editor_and_return_to_original()
      vim.api.nvim_put({ state.get().last_result }, "c", true, true)
    end, opts)

    -- YANK option - copy to clipboard and return to editor
    vim.keymap.set("n", "y", function()
      local last_result = state.get().last_result
      vim.fn.setreg("+", last_result)
      vim.fn.setreg('"', last_result)
      print("Result copied to clipboard")
      ui.close_result_popup()
    end, opts)
  end
end

return M
