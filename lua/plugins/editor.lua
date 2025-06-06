return {
  -- File explorer
  {
    'nvim-tree/nvim-tree.lua',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require("nvim-tree").setup({
        filters = {
          dotfiles = false,
          git_clean = false,
          no_buffer = false,
          custom = {},
        },
        git = {
          enable = true,
          ignore = false,
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
    end
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end
  },

  -- Comments
  {
    "preservim/nerdcommenter",
    lazy = false,
    config = function()
      -- Disable all default mappings
      vim.g.NERDCreateDefaultMappings = 0

      -- Keep your preferred settings
      vim.g.NERDCommentEmptyLines = 1
      vim.g.NERDSpaceDelims = 1

      -- Create only the toggle mapping
      vim.keymap.set({'n', 'v'}, '<leader>c<space>', '<plug>NERDCommenterToggle', { desc = 'Toggle comment' })
    end
  },

  -- Undo tree
  {
    'mbbill/undotree',
    config = function()
      vim.g.undotree_WindowLayout = 2
      vim.g.undotree_ShortIndicators = 1
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.keymap.set('n', '<leader>u', ':UndotreeToggle<CR>', { desc = 'Toggle undo tree' })
    end
  },

  -- Session management
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
        hooks = {
          before_save = function(_)
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(bufnr) then
                local buftype = vim.bo[bufnr].buftype
                local bufname = vim.api.nvim_buf_get_name(bufnr)

                if buftype == 'terminal' or bufname:match('term://') or bufname:match('toggleterm') then
                  vim.bo[bufnr].modified = false
                  pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
                end
              end
            end
            return true
          end,
          after_save = function(name)
            print("Session '" .. name .. "' saved successfully")
          end,
          before_load = function(_)
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(bufnr) then
                local buftype = vim.bo[bufnr].buftype
                if buftype == 'terminal' then
                  vim.bo[bufnr].modified = false
                  pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
                end
              end
            end
            return true
          end,
          after_load = function(_)
            -- Update nvim-tree root to the current working directory
            local cwd = vim.fn.getcwd()
            require('nvim-tree.api').tree.change_root(cwd)
            require('nvim-tree.api').tree.reload()
          end,
        },
        plugins = {
          close_windows = false,
          delete_hidden_buffers = false,
        },
      }

      -- Session management keymaps
      vim.keymap.set('n', '<leader>ss', ':PossessionSave<CR>', { desc = 'Save session' })
      vim.keymap.set('n', '<leader>sl', ':PossessionLoad ', { desc = 'Load session' })
      vim.keymap.set('n', '<leader>sd', ':PossessionDelete<CR>', { desc = 'Delete session' })
      vim.keymap.set('n', '<leader>sr', ':PossessionRename<CR>', { desc = 'Rename session' })
    end
  },
}
