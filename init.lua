-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true


-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    {
      'nvim-tree/nvim-tree.lua',
      lazy = true,
      dependencies = {
        'nvim-tree/nvim-web-devicons',
      },
    },
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    {
      'nvim-telescope/telescope.nvim', branch = '0.1.x',
      dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {
      "preservim/nerdcommenter",
      lazy = false, -- Prevent lazy loading issues
      config = function()
        -- Create default mappings
        vim.g.NERDCreateDefaultMappings = 1
        vim.g.NERDCommentEmptyLines = 1
        vim.g.NERDSpaceDelims = 1
        -- vim.g.NERDCompactSexyComs = 1
        -- etc.
      end
    },
    {
      'jedrzejboczar/possession.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
      config = function()
        require('possession').setup {
          session_dir = vim.fn.expand(vim.fn.stdpath('data') .. '/sessions'),
          silent = false,
          load_silent = true,
          debug = false,
          logfile = false,
          prompt_no_cr = false,
          autosave = {
            current = false,
            tmp = false,
            tmp_name = 'tmp',
            on_load = true,
            on_quit = true,
          },
          commands = {
            save = 'PossessionSave',
            load = 'PossessionLoad',
            rename = 'PossessionRename',
            close = 'PossessionClose',
            delete = 'PossessionDelete',
            show = 'PossessionShow',
            list = 'PossessionList',
            migrate = 'PossessionMigrate',
          },
        }

        -- Load Telescope extension
        require('telescope').load_extension('possession')
      end
    },{
      'lewis6991/gitsigns.nvim',
      config = function()
        require('gitsigns').setup({
          signs = {
            add          = { text = '┃' },
            change       = { text = '┃' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
          },
          current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
          current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = false,
          },
          on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
              opts = opts or {}
              opts.buffer = bufnr
              vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map('n', ']c', function()
              if vim.wo.diff then return ']c' end
              vim.schedule(function() gs.next_hunk() end)
              return '<Ignore>'
            end, {expr=true})

            map('n', '[c', function()
              if vim.wo.diff then return '[c' end
              vim.schedule(function() gs.prev_hunk() end)
              return '<Ignore>'
            end, {expr=true})

            -- Actions
            map('n', '<leader>hs', gs.stage_hunk)
            map('n', '<leader>hr', gs.reset_hunk)
            map('n', '<leader>hS', gs.stage_buffer)
            map('n', '<leader>hu', gs.undo_stage_hunk)
            map('n', '<leader>hR', gs.reset_buffer)
            map('n', '<leader>hp', gs.preview_hunk)
            map('n', '<leader>hb', function() gs.blame_line{full=true} end)
            map('n', '<leader>tb', gs.toggle_current_line_blame)
            map('n', '<leader>hd', gs.diffthis)
            map('n', '<leader>hD', function() gs.diffthis('~') end)
            map('n', '<leader>td', gs.toggle_deleted)
          end
        })
      end
    }
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

-- empty setup using defaults
require("nvim-tree").setup()


vim.api.nvim_set_keymap('n', '<Leader>t', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
-- Buffer navigation
vim.keymap.set('n', '<leader>bn', ':bnext<CR>', { noremap = true })
vim.keymap.set('n', '<leader>bp', ':bprevious<CR>', { noremap = true })
vim.keymap.set('n', '<leader>bd', ':bdelete<CR>', { noremap = true })
vim.keymap.set('n', '<leader>ls', ':ls<CR>', { noremap = true })


-- FuzzyFind (telescope)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- Session management keymaps
vim.keymap.set('n', '<leader>ss', ':PossessionSave<CR>', { desc = 'Save session' })
vim.keymap.set('n', '<leader>sl', ':PossessionLoad<CR>', { desc = 'Load session' })
vim.keymap.set('n', '<leader>sf', '<cmd>Telescope possession list<CR>', { desc = 'Find sessions' })
vim.keymap.set('n', '<leader>sd', ':PossessionDelete<CR>', { desc = 'Delete session' })
vim.keymap.set('n', '<leader>sr', ':PossessionRename<CR>', { desc = 'Rename session' })

-- Use spaces instead of tabs
vim.opt.expandtab = true      -- Convert tabs to spaces
vim.opt.tabstop = 2           -- Number of spaces a tab counts for
vim.opt.shiftwidth = 2        -- Number of spaces to use for autoindent
vim.opt.softtabstop = 2       -- Number of spaces a tab counts for when editing
vim.opt.wrap = false -- Disable line wrapping
vim.opt.mouse = 'a'
-- vim.opt.clipboard = 'unnamedplus'
vim.opt.hidden = true -- Allow switching buffers without saving
