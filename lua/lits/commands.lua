-- lua/lits/commands.lua
local M = {}

local function open_lits_editor(use_selection)
  require("lits.editor").open(use_selection)
end

function M.setup()
  -- Commands
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

  -- Keymaps can be added here or kept in the plugin file
  -- vim.keymap.set("n", "<leader>L", ":Lits<cr>", { desc = "Lits" })
  -- vim.keymap.set("v", "<leader>L", ":Lits<cr>", { desc = "Lits" })
end

return M
