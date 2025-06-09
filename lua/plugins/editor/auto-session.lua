return {
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
        if not os.getenv("TERM_PROGRAM") or os.getenv("TERM_PROGRAM") ~= "iTerm.app" then
          return
        end

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
            vim.defer_fn(function()
              if pcall(require, 'nvim-tree.api') then
                local cwd = vim.fn.getcwd()
                require('nvim-tree.api').tree.change_root(cwd)
                require('nvim-tree.api').tree.reload()
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
  }
}

