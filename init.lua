_G.original_nvim_args = {
  cwd = vim.fn.getcwd(),
  argc = vim.fn.argc(),
  argv = {}
}

for i = 0, vim.fn.argc() - 1 do
  _G.original_nvim_args.argv[i] = vim.fn.argv(i)
end

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- Make sure to setup `mapleader` and `maplocalleader` before loading lazy.nvim
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load configuration modules
require("config")
require("lits").setup()
