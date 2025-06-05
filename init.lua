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
            current = true,
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
    },
    {
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
    },
    {
      'akinsho/toggleterm.nvim',
      version = "*",
      config = function()
        require("toggleterm").setup({
          size = 15,
          open_mapping = [[<leader>tt]],
          hide_numbers = true,
          shade_terminals = true,
          shading_factor = 2,
          start_in_insert = true,
          insert_mappings = true,
          persist_size = true,
          direction = 'horizontal', -- 'vertical' | 'horizontal' | 'tab' | 'float'
          close_on_exit = true,
          shell = vim.o.shell,
          float_opts = {
            border = 'curved',
            winblend = 0,
            highlights = {
              border = "Normal",
              background = "Normal",
            }
          }
        })

        -- Custom terminal keymaps
        function _G.set_terminal_keymaps()
          local opts = {buffer = 0}
          vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
          vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
          vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
          vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
          vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        end

        vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

        -- Additional keymaps for different terminal types
        local Terminal = require('toggleterm.terminal').Terminal

        -- Floating terminal
        local float_term = Terminal:new({
          direction = "float",
          float_opts = {
            border = "double",
          },
          hidden = true,
        })

        function _FLOAT_TOGGLE()
          float_term:toggle()
        end

        vim.keymap.set('n', '<leader>tf', '<cmd>lua _FLOAT_TOGGLE()<CR>', { desc = 'Toggle floating terminal' })
      end
    },
    {
      'akinsho/bufferline.nvim',
      version = "*",
      dependencies = 'nvim-tree/nvim-web-devicons',
      config = function()
        require("bufferline").setup({
          options = {
            mode = "buffers", -- set to "tabs" to only show tabpages instead
            numbers = "none", -- "none" | "ordinal" | "buffer_id" | "both"
            close_command = "bdelete! %d",
            right_mouse_command = "bdelete! %d",
            left_mouse_command = "buffer %d",
            middle_mouse_command = nil,
            indicator = {
              icon = '▎',
              style = 'icon',
            },
            buffer_close_icon = '󰅖',
            modified_icon = '●',
            close_icon = '',
            left_trunc_marker = '',
            right_trunc_marker = '',
            diagnostics = "nvim_lsp", -- Show LSP diagnostics
            diagnostics_update_in_insert = false,
            show_buffer_icons = true,
            show_buffer_close_icons = true,
            show_close_icon = true,
            show_tab_indicators = true,
            separator_style = "slant", -- "slant" | "thick" | "thin" | { 'any', 'any' }
            enforce_regular_tabs = false,
            always_show_bufferline = true,
            hover = {
              enabled = true,
              delay = 200,
              reveal = {'close'}
            },
            offsets = {
              {
                filetype = "NvimTree",
                text = "File Explorer",
                text_align = "left",
                separator = true
              }
            },
          }
        })
      end
    },
    {
      'akinsho/bufferline.nvim',
      version = "*",
      dependencies = 'nvim-tree/nvim-web-devicons',
      config = function()
        require("bufferline").setup({
          options = {
            mode = "buffers",
            numbers = "none",
            close_command = "bdelete! %d",
            right_mouse_command = "bdelete! %d",
            left_mouse_command = "buffer %d",
            middle_mouse_command = nil,
            indicator = {
              icon = '▎',
              style = 'icon',
            },
            buffer_close_icon = '󰅖',
            modified_icon = '●',
            close_icon = '',
            left_trunc_marker = '',
            right_trunc_marker = '',
            diagnostics = "nvim_lsp",
            show_buffer_icons = true,
            show_buffer_close_icons = true,
            show_close_icon = true,
            show_tab_indicators = true,
            separator_style = "slant",
            always_show_bufferline = true,
            hover = {
              enabled = true,
              delay = 200,
              reveal = {'close'}
            },
            -- Filter out directory buffers and nvim-tree
            custom_filter = function(buf_number, buf_numbers)
              local buf_name = vim.api.nvim_buf_get_name(buf_number)
              local buf_ft = vim.bo[buf_number].filetype

              -- Hide directory buffers and nvim-tree
              if buf_ft == "NvimTree" then
                return false
              end

              -- Hide directory buffers (they usually end with / or are directories)
              if vim.fn.isdirectory(buf_name) == 1 then
                return false
              end

              -- Hide unnamed buffers that are directories
              if buf_name == "" or buf_name:match("/$") then
                return false
              end

              return true
            end,
            offsets = {
              {
                filetype = "NvimTree",
                text = "File Explorer",
                text_align = "left",
                separator = true
              }
            },
          }
        })
      end
    },
    {
      'mbbill/undotree',
      config = function()
        -- Configure undotree
        vim.g.undotree_WindowLayout = 2
        vim.g.undotree_ShortIndicators = 1
        vim.g.undotree_SetFocusWhenToggle = 1

        -- Keymap to toggle undotree
        vim.keymap.set('n', '<leader>u', ':UndotreeToggle<CR>', { desc = 'Toggle undo tree' })
      end
    },
    -- Better colorscheme
    {
      'catppuccin/nvim',
      name = 'catppuccin',
      priority = 1000,
      config = function()
        require('catppuccin').setup({
          flavour = 'mocha', -- latte, frappe, macchiato, mocha
          transparent_background = false,
          integrations = {
            nvimtree = true,
            telescope = true,
            gitsigns = true,
            bufferline = true,
          },
        })
        vim.cmd.colorscheme('catppuccin')
      end
    },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

require("nvim-tree").setup({
  filters = {
    dotfiles = false,  -- Show dotfiles like .gitignore
    git_clean = false, -- Show files ignored by git
    no_buffer = false,
    custom = {
      -- Remove lazy-lock.json from the default ignore list
      -- You can add other files you want to hide here
    },
  },
  git = {
    enable = true,
    ignore = false,  -- Show git ignored files
    show_on_dirs = true,
    show_on_open_dirs = true,
    timeout = 400,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
})


vim.api.nvim_set_keymap('n', '<leader>te', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

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

-- Buffer navigation with Ctrl+Tab and Ctrl+Shift+Tab
vim.keymap.set('n', '<M-Tab>', ':BufferLineCycleNext<CR>', { noremap = true, silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<M-S-Tab>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc = 'Previous buffer' })


-- Use spaces instead of tabs
vim.opt.expandtab = true      -- Convert tabs to spaces
vim.opt.tabstop = 2           -- Number of spaces a tab counts for
vim.opt.shiftwidth = 2        -- Number of spaces to use for autoindent
vim.opt.softtabstop = 2       -- Number of spaces a tab counts for when editing
vim.opt.wrap = false -- Disable line wrapping
vim.opt.mouse = 'a'
-- vim.opt.clipboard = 'unnamedplus'
vim.opt.hidden = true -- Allow switching buffers without saving

-- Disable swapfiles
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Show line numbers
vim.opt.number = true

-- Simple keymap to quit all
vim.keymap.set('n', '<leader>qa', ':qall<CR>', { desc = 'Quit all' })

-- Window navigation with Option+Arrow keys (including terminal mode)
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

-- Auto-save buffers
vim.api.nvim_create_autocmd({"FocusLost", "BufLeave", "CursorHold", "CursorHoldI"}, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command('silent! write')
    end
  end,
})

-- Enable persistent undo (add this with your other vim.opt settings)
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'
vim.opt.undolevels = 10000
vim.opt.undoreload = 10000
