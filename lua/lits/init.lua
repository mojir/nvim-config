-- lua/lits/init.lua
local M = {}

-- Import modules
local config = require("lits.config")
local state = require("lits.state")
local utils = require("lits.utils")
local ui = require("lits.ui")
local files = require("lits.files")

-- Import functionality modules
local editor = require("lits.editor")
local commands = require("lits.commands")

function M.setup(opts)
  opts = opts or {}

  -- Setup configuration
  config.setup(opts)
  
  -- Load session data to restore file state
  state.load_session_data()
  
  -- Determine starting file
  local starting_file = files.get_starting_file()
  state.set("current_file", starting_file)

  -- Create main autocmd group
  local autocmd_group = vim.api.nvim_create_augroup("LitsPlugin", { clear = true })
  state.set_autocmd_group(autocmd_group)

  -- Initialize directory and load appropriate program
  vim.defer_fn(function()
    if utils.ensure_programs_dir() then
      local program_content = utils.load_program(starting_file)
      state.set("current_program", program_content)
      state.set_initialized(true)
    else
      vim.notify("Failed to initialize Lits plugin", vim.log.levels.ERROR)
    end
  end, 10)

  -- Setup cleanup and session saving on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = autocmd_group,
    callback = function()
      state.save_session_data()
      ui.cleanup_state()
    end,
  })

  -- Setup commands
  commands.setup()
end

-- Public API functions
function M.open_editor(use_selection)
  return editor.open(use_selection)
end

function M.evaluate_and_show()
  return editor.evaluate_and_show()
end

function M.evaluate_and_insert()
  return editor.evaluate_and_insert()
end

-- Additional API functions for file management
function M.save_as()
  return files.save_as_dialog()
end

function M.open_file()
  return files.open_file_picker()
end

function M.new_file()
  return files.new_file_dialog()
end

function M.delete_file()
  return files.delete_current_file()
end

function M.list_files()
  return files.list_files()
end

return M
