-- Global keymaps that don't belong to specific plugins

-- Simple keymap to quit all
vim.keymap.set('n', '<leader>qa', ':qall<CR>', { desc = 'Quit all' })

-- Window navigation with Option+Arrow keys
local nav_maps = {
  ['<M-Left>'] = '<C-w>h',
  ['<M-Right>'] = '<C-w>l',
  ['<M-Up>'] = '<C-w>k',
  ['<M-Down>'] = '<C-w>j'
}

for key, cmd in pairs(nav_maps) do
  vim.keymap.set('n', key, cmd, { desc = 'Navigate windows' })
  vim.keymap.set('t', key, '<C-\\><C-n>' .. cmd, { desc = 'Navigate from terminal' })
end

-- Buffer/tab navigation with bufferline
vim.keymap.set('n', '<leader>bc', ':BufferLineCloseRight<CR>:BufferLineCloseLeft<CR>', { noremap = true, desc = 'Close all but current' })
vim.keymap.set('n', '<leader>ls', ':ls<CR>', { noremap = true })

-- Quick buffer switching with numbers
vim.keymap.set('n', '<leader>1', '<Cmd>BufferLineGoToBuffer 1<CR>', { desc = 'Go to buffer 1' })
vim.keymap.set('n', '<leader>2', '<Cmd>BufferLineGoToBuffer 2<CR>', { desc = 'Go to buffer 2' })
vim.keymap.set('n', '<leader>3', '<Cmd>BufferLineGoToBuffer 3<CR>', { desc = 'Go to buffer 3' })
vim.keymap.set('n', '<leader>4', '<Cmd>BufferLineGoToBuffer 4<CR>', { desc = 'Go to buffer 4' })
vim.keymap.set('n', '<leader>5', '<Cmd>BufferLineGoToBuffer 5<CR>', { desc = 'Go to buffer 5' })
vim.keymap.set('n', '<leader>6', '<Cmd>BufferLineGoToBuffer 6<CR>', { desc = 'Go to buffer 6' })
vim.keymap.set('n', '<leader>7', '<Cmd>BufferLineGoToBuffer 7<CR>', { desc = 'Go to buffer 7' })
vim.keymap.set('n', '<leader>8', '<Cmd>BufferLineGoToBuffer 8<CR>', { desc = 'Go to buffer 8' })
vim.keymap.set('n', '<leader>9', '<Cmd>BufferLineGoToBuffer 9<CR>', { desc = 'Go to buffer 9' })

-- Buffer navigation with tab key
vim.keymap.set('n', '<Tab>', ':BufferLineCycleNext<CR>', { noremap = true, silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc = 'Previous buffer' })

-- Clipboard operations using + register
vim.keymap.set('n', '<leader>y', '"+y', { desc = 'Yank to clipboard' })
vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Yank to clipboard' })
vim.keymap.set('n', '<leader>yy', '"+yy', { desc = 'Yank line to clipboard' })
vim.keymap.set('n', '<leader>d', '"+d', { desc = 'Delete to clipboard' })
vim.keymap.set('v', '<leader>d', '"+d', { desc = 'Delete to clipboard' })
vim.keymap.set('n', '<leader>dd', '"+dd', { desc = 'Delete line to clipboard' })
vim.keymap.set('n', '<leader>p', '"+p', { desc = 'Paste from clipboard after cursor' })
vim.keymap.set('n', '<leader>P', '"+P', { desc = 'Paste from clipboard before cursor' })
vim.keymap.set('v', '<leader>p', '"+p', { desc = 'Paste from clipboard' })

-- Git status with Telescope
vim.keymap.set('n', '<leader>gs', function()
  require('telescope.builtin').git_status()
end, { desc = 'Git status (Telescope)' })

-- Load utility functions for diagnostics
require("utils.diagnostic")

-- Simple function to close all buffers outside nvim-tree root
local function close_buffers_outside_root()
  local root_path = vim.fn.getcwd()
  local closed_count = 0

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local buftype = vim.bo[bufnr].buftype

      -- Only check regular file buffers
      if buftype == '' and bufname ~= '' then
        local buf_dir = vim.fn.fnamemodify(bufname, ':p:h')

        -- Check if buffer is outside root directory
        -- Normalize paths to ensure proper comparison
        local normalized_buf_dir = vim.fn.resolve(buf_dir)
        local normalized_root = vim.fn.resolve(root_path)

        -- Check if buffer path starts with root path
        local is_under_root = normalized_buf_dir:find('^' .. vim.pesc(normalized_root))

        if not is_under_root then
          pcall(function()
            vim.bo[bufnr].modified = false
            vim.api.nvim_buf_delete(bufnr, { force = true })
            closed_count = closed_count + 1
          end)
        end
      end
    end
  end

  print(string.format("Closed %d buffer(s) outside root: %s", closed_count, root_path))
end

-- Create the command
vim.api.nvim_create_user_command('CloseOutsideRoot', close_buffers_outside_root, {
  desc = 'Close all file buffers outside nvim-tree root directory'
})


