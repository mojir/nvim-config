local config = require("session.config")
local core = require("session.core")
local tracking = require("session.tracking")

local M = {}

function M.session_picker()
  local session_items = core.get_sorted_sessions_with_display()
  
  if #session_items == 0 then
    print("No sessions found")
    return
  end
  
  local ok = pcall(require, "telescope")
  if not ok then
    core.list_sessions()
    return
  end
  
  require("telescope.pickers")
    .new({}, {
      prompt_title = "Sessions (sorted by last used)",
      finder = require("telescope.finders").new_table({
        results = session_items,
        entry_maker = function(entry)
          return {
            value = entry.name,
            display = entry.display,
            ordinal = entry.name,
            path = entry.dir,
          }
        end,
      }),
      sorter = require("telescope.config").values.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        -- Default action (Enter) - switch to session
        require("telescope.actions").select_default:replace(function()
          local selection = require("telescope.actions.state").get_selected_entry()
          require("telescope.actions").close(prompt_bufnr)
          
          if selection then
            core.switch_to_session(selection.value)
          end
        end)
        
        -- Add delete action with <C-d>
        vim.keymap.set("i", "<C-d>", function()
          local selection = require("telescope.actions.state").get_selected_entry()
          if selection then
            local current_session = config.get_session_name()
            
            -- Confirm deletion
            local choice = vim.fn.confirm(
              "Delete session: " .. selection.value .. "?",
              "&Delete\n&Cancel",
              2
            )
            
            if choice ~= 1 then
              return
            end
            
            -- Delete session directory
            vim.fn.delete(selection.path, "rf")
            
            -- If deleting current session, clear marks and tracking
            if selection.value == current_session then
              for i = 65, 90 do
                local mark = string.char(i)
                vim.cmd("silent! delmarks " .. mark)
              end
              tracking.clear_access_history()
              print("Deleted current session: " .. selection.value)
            else
              print("Deleted session: " .. selection.value)
            end
            
            -- Refresh the picker
            require("telescope.actions").close(prompt_bufnr)
            vim.defer_fn(M.session_picker, 50)
          end
        end, { buffer = prompt_bufnr })
        
        return true
      end,
    })
    :find()
end

return M
