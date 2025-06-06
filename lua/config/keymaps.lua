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
vim.keymap.set('n', '<leader>bn', ':BufferLineCycleNext<CR>', { noremap = true, desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', ':BufferLineCyclePrev<CR>', { noremap = true, desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>bd', ':BufferLinePickClose<CR>', { noremap = true, desc = 'Pick buffer to close' })
vim.keymap.set('n', '<leader>bc', ':BufferLineCloseRight<CR>:BufferLineCloseLeft<CR>', { noremap = true, desc = 'Close all but current' })
vim.keymap.set('n', '<leader>ls', ':ls<CR>', { noremap = true })

-- Quick buffer switching with numbers
vim.keymap.set('n', '<leader>1', '<Cmd>BufferLineGoToBuffer 1<CR>', { desc = 'Go to buffer 1' })
vim.keymap.set('n', '<leader>2', '<Cmd>BufferLineGoToBuffer 2<CR>', { desc = 'Go to buffer 2' })
vim.keymap.set('n', '<leader>3', '<Cmd>BufferLineGoToBuffer 3<CR>', { desc = 'Go to buffer 3' })
vim.keymap.set('n', '<leader>4', '<Cmd>BufferLineGoToBuffer 4<CR>', { desc = 'Go to buffer 4' })
vim.keymap.set('n', '<leader>5', '<Cmd>BufferLineGoToBuffer 5<CR>', { desc = 'Go to buffer 5' })

-- Buffer navigation with Alt+Tab
vim.keymap.set('n', '<M-Tab>', ':BufferLineCycleNext<CR>', { noremap = true, silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<M-S-Tab>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc = 'Previous buffer' })

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

-- Load utility functions for diagnostics
require("utils.diagnostic")
