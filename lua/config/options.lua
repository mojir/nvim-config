-- Vim options and settings
local opt = vim.opt

-- Use spaces instead of tabs
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.wrap = false
opt.mouse = "a"

-- Disable swapfiles
opt.swapfile = false
opt.writebackup = false

-- Show line numbers
opt.number = true

-- Enable persistent undo
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"

opt.signcolumn = "auto:2"

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.o.showtabline = 0 -- Hide tabline by default

-- Allow cursor to move beyond end of line in visual block mode
vim.opt.virtualedit = "block"
