-- lua/lits/commands.lua
local M = {}

local function open_lits_editor(use_selection)
  require("lits.editor").open(use_selection)
end

function M.setup()
  -- Main Lits command
  vim.api.nvim_create_user_command("Lits", function(cmd_opts)
    if cmd_opts.range == 2 then
      -- Called from visual mode
      open_lits_editor(true)
    else
      -- Called from normal mode
      open_lits_editor(false)
    end
  end, {
    range = true,
    desc = "Open Lits program editor",
  })

  -- File management commands
  vim.api.nvim_create_user_command("LitsSaveAs", function()
    require("lits.files").save_as_dialog()
  end, {
    desc = "Save current Lits program with new name",
  })

  vim.api.nvim_create_user_command("LitsOpen", function()
    require("lits.files").open_file_picker()
  end, {
    desc = "Open existing Lits program",
  })

  vim.api.nvim_create_user_command("LitsNew", function()
    require("lits.files").new_file_dialog()
  end, {
    desc = "Create new Lits program",
  })

  vim.api.nvim_create_user_command("LitsDelete", function()
    require("lits.files").delete_current_file()
  end, {
    desc = "Delete current Lits program",
  })

  vim.api.nvim_create_user_command("LitsList", function()
    local files = require("lits.files").list_files()
    if #files == 0 then
      print("No Lits files found")
    else
      print("Lits programs:")
      for _, file in ipairs(files) do
        print("  " .. file)
      end
    end
  end, {
    desc = "List all Lits programs",
  })

  -- Evaluation commands (can be used from outside the editor)
  vim.api.nvim_create_user_command("LitsEval", function(cmd_opts)
    if cmd_opts.range == 2 then
      -- Evaluate selection
      local utils = require("lits.utils")
      local selection = utils.get_visual_selection()
      if selection ~= "" then
        -- Save selection to a temp program and evaluate
        local temp_file = "TEMP_EVAL.lits"
        if utils.save_program(selection, temp_file) then
          local state = require("lits.state")
          local old_file = state.get().current_file
          state.set("current_file", temp_file)
          
          local success, result = utils.evaluate_lits()
          
          -- Restore old file and clean up
          state.set("current_file", old_file)
          require("lits.files").delete_program(temp_file)
          
          if success then
            print("Result: " .. result)
          else
            print("Error: " .. result)
          end
        end
      end
    else
      print("LitsEval requires a visual selection")
    end
  end, {
    range = true,
    desc = "Evaluate selected Lits code",
  })
end

return M
