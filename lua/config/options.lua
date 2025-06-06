-- Vim options and settings
local opt = vim.opt

-- Use spaces instead of tabs
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.wrap = false
opt.mouse = 'a'
opt.hidden = true

-- Disable swapfiles
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- Show line numbers
opt.number = true

-- Enable persistent undo
opt.undofile = true
opt.undodir = vim.fn.stdpath('data') .. '/undo'
opt.undolevels = 10000
opt.undoreload = 10000
