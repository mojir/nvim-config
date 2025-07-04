-- lua/lits/init.lua
local M = {}

-- Import modules
local config = require("lits.config")
local state = require("lits.state")
local utils = require("lits.utils")
local ui = require("lits.ui")

-- Import functionality modules (to be created)
local editor = require("lits.editor")
local result = require("lits.result")
local commands = require("lits.commands")

function M.setup(opts)
  opts = opts or {}

  -- Setup configuration
  config.setup(opts)
  
  -- Set initial state
  state.set("current_file", config.get().default_file)

  -- Create main autocmd group
  local autocmd_group = vim.api.nvim_create_augroup("LitsPlugin", { clear = true })
  state.set_autocmd_group(autocmd_group)

  -- Initialize directory and load default program
  vim.defer_fn(function()
    if utils.ensure_programs_dir() then
      local program_content = utils.load_program(state.get().current_file)
      state.set("current_program", program_content)
      state.set_initialized(true)
    else
      vim.notify("Failed to initialize Lits plugin", vim.log.levels.ERROR)
    end
  end, 10)

  -- Setup cleanup on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = autocmd_group,
    callback = ui.cleanup_state,
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

return M
