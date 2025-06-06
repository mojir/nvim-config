-- Enable basic exrc support
vim.opt.exrc = true
vim.opt.secure = true

-- Function to load .nvim.lua files
local function load_project_lua_config()
  local config_files = {
    vim.fn.getcwd() .. '/.nvim.lua',
    vim.fn.getcwd() .. '/.nvimrc.lua',
  }

  for _, config_file in ipairs(config_files) do
    if vim.fn.filereadable(config_file) == 1 then
      -- Security check: only load if we trust this directory
      local cwd = vim.fn.getcwd()
      local home = vim.fn.expand('~')

      -- Only auto-load from home directory and subdirectories by default
      -- You can modify this logic based on your security preferences
      if cwd:sub(1, #home) == home or vim.fn.confirm('Load project config from ' .. config_file .. '?', '&Yes\n&No', 2) == 1 then
        local ok, err = pcall(dofile, config_file)
        if ok then
          print('✓ Loaded project config: ' .. vim.fn.fnamemodify(config_file, ':t'))
        else
          print('✗ Error loading project config: ' .. err)
        end
        break -- Only load the first one found
      end
    end
  end
end

-- Auto-load project configs when changing directories or starting Neovim
vim.api.nvim_create_autocmd({'DirChanged', 'VimEnter'}, {
  group = vim.api.nvim_create_augroup('ProjectLuaConfig', { clear = true }),
  callback = function()
    -- Small delay to ensure directory is fully changed
    vim.defer_fn(load_project_lua_config, 50)
  end,
})

-- Manual reload command
vim.api.nvim_create_user_command('ProjectReload', load_project_lua_config, {
  desc = 'Reload project .nvim.lua configuration'
})

-- Keymap for manual reload
vim.keymap.set('n', '<leader>rp', load_project_lua_config, { desc = 'Reload project config' })
