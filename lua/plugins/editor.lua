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
        -- NEW: Auto-sync with current buffer
        -- update_focused_file = {
        -- enable = true,
        -- update_root = false,  -- Don't change root when switching files
        -- ignore_list = {},
        -- },
        -- NEW: Enable file system watcher for real-time updates
        filesystem_watchers = {
          enable = true,
          debounce_delay = 50,
          ignore_dirs = {
            "node_modules",
            ".git",
          },
        },
      })

      vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
      vim.keymap.set('n', '<leader>tg', function()
        local api = require('nvim-tree.api')
        if api.tree.is_visible() then
          api.tree.find_file({ focus = true })
        else
          api.tree.open({ find_file = true })
        end
      end, {
          desc = 'Toggle tree and find current file'
        })
    end
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>fm', '<cmd>Telescope marks<cr>', { desc = 'Show registers' })
      vim.keymap.set('n', '<leader>fr', '<cmd>Telescope registers<cr>', { desc = 'Show registers' })
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end
  },

  -- Comments
  {
    "preservim/nerdcommenteR",
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
  -- Auto-session with bundled session-lens (single plugin)
  {
    'rmagatti/auto-session',
    lazy = false,
    dependencies = {
      'nvim-telescope/telescope.nvim', -- Only telescope is needed
    },
    config = function()
      -- Function to update iTerm window title
      local function update_iterm_title()
        local current_session = vim.v.this_session

        if current_session and current_session ~= '' then
          local session_name = vim.fn.fnamemodify(current_session, ':t:r')
          io.write('\027]0;' .. session_name .. '\007')
          io.flush()
        else
          local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
          io.write('\027]0;nvim: ' .. cwd .. '\007')
          io.flush()
        end
      end
      require('auto-session').setup({
        -- Basic session settings
        auto_session_root_dir = vim.fn.stdpath('data') .. '/sessions/',
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = false, -- Manual restore only
        auto_session_create_enabled = false, -- Don't auto-create

        -- Suppress for certain directories
        auto_session_suppress_dirs = {
          '~/',
          '~/Downloads',
          '~/Documents',
          '~/Desktop',
          '/tmp',
        },

        -- Logging
        log_level = 'error',

        -- Hooks for nvim-tree integration
        pre_save_cmds = {
          function()
            -- Close nvim-tree before saving
            if pcall(require, 'nvim-tree.api') then
              require('nvim-tree.api').tree.close()
            end
          end,
        },

        post_restore_cmds = {
          function()
            -- Update and open nvim-tree after restoring
            vim.defer_fn(function()
              if pcall(require, 'nvim-tree.api') then
                local cwd = vim.fn.getcwd()
                require('nvim-tree.api').tree.change_root(cwd)
                require('nvim-tree.api').tree.reload()
                require('nvim-tree.api').tree.open()
              end
            end, 100)
          end,
          update_iterm_title, -- Update iTerm title after restoring
        },


        -- Built-in session-lens configuration
        session_lens = {
          -- Load session-lens on setup
          load_on_setup = true,

          -- Telescope theme configuration
          theme_conf = {
            border = true,
            layout_config = {
              width = 0.8,
              height = 0.6,
            },
          },

          -- Don't show session file preview
          previewer = false,

          -- Custom session display
          path_display = { 'smart' },

          -- Prompt title
          prompt_title = 'Sessions',
        },
      })

      -- Auto-update title on vim enter
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = update_iterm_title,
      })

      -- Session management functions
      local function save_session()
        local session_name = vim.fn.input('Session name: ')
        if session_name and session_name ~= '' then
          require('auto-session').SaveSession(session_name)
          print('Session "' .. session_name .. '" saved')
        end
      end

      -- Session keymaps
      vim.keymap.set('n', '<leader>ss', save_session, { desc = 'Save session' })
      -- Session picker using built-in session-lens
      vim.keymap.set('n', '<leader>sp', function()
        require('auto-session.session-lens').search_session({})
      end, { desc = 'Pick session (Telescope)' })

      -- Load the telescope extension (built-in)
      vim.defer_fn(function()
        if pcall(require, 'telescope') then
          require('telescope').load_extension('session-lens')
        end
      end, 100)
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  }
}
