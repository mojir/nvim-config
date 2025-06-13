return {
  -- Auto-session with bundled session-lens (single plugin)
  {
    'rmagatti/auto-session',
    lazy = false,
    dependencies = {
      'nvim-telescope/telescope.nvim', -- Only telescope is needed
    },
    config = function()
      require('auto-session').setup({
        -- Basic session settings
        auto_session_root_dir = vim.fn.stdpath('data') .. '/sessions/',
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        auto_session_create_enabled = true,

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
            vim.defer_fn(function()
              if pcall(require, 'nvim-tree.api') then
                local cwd = vim.fn.getcwd()
                require('nvim-tree.api').tree.change_root(cwd)
                require('nvim-tree.api').tree.reload()
              end
            end, 100)
          end,
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

      -- Session picker using built-in session-lens
      vim.keymap.set('n', '<leader>sp', function()
        require('auto-session.session-lens').search_session({})
      end, { desc = 'Pick session (Telescope)' })

      -- Explicit session save
      vim.keymap.set('n', '<leader>ss', function()
        require('auto-session').SaveSession()
      end, { desc = 'Save current session' })
      
      -- Load the telescope extension (built-in)
      vim.defer_fn(function()
        if pcall(require, 'telescope') then
          require('telescope').load_extension('session-lens')
        end
      end, 100)
    end,
  }
}

