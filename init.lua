-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- Bootstrap lazy.nvim (FIXED: Compatible with all Neovim versions)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.fn.isdirectory(lazypath) then
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

-- Make sure to setup `mapleader` and `maplocalleader` before loading lazy.nvim
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    {
      'neovim/nvim-lspconfig',
      dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',
      },
      config = function()
        -- Mason setup
        require('mason').setup({
          ui = {
            border = "rounded",
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗"
            }
          }
        })

        -- FIXED: Use correct field name for mason-lspconfig
        require('mason-lspconfig').setup({
          ensure_installed = {
            'lua_ls',           -- Lua
            'ts_ls',            -- TypeScript/JavaScript
            'pyright',          -- Python
            'bashls',           -- Bash/Shell
            'html',             -- HTML
            'cssls',            -- CSS
            'emmet_ls',         -- Emmet for HTML/CSS
          },
          automatic_enable = true,  -- FIXED: Changed from automatic_installation
        })

        local lspconfig = require('lspconfig')
        local cmp_nvim_lsp = require('cmp_nvim_lsp')
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- First, setup the custom lua_ls configuration
        lspconfig.lua_ls.setup({
          capabilities = capabilities,
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              diagnostics = {
                globals = { 'vim' },
                disable = { 'trailing-space' }  -- Disable trailing space warnings
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file('', true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
              format = { enable = false },  -- Disable lua_ls formatting
            },
          },
        })

        -- Then setup other servers with a delay to ensure handlers are available
        vim.defer_fn(function()
          local mason_lspconfig = require('mason-lspconfig')

          -- Check if setup_handlers exists
          if mason_lspconfig.setup_handlers then
            mason_lspconfig.setup_handlers({
              -- Default handler for servers (skip lua_ls since we already set it up)
              function(server_name)
                if server_name == "lua_ls" then
                  return -- Skip lua_ls since we already configured it
                end
                lspconfig[server_name].setup({
                  capabilities = capabilities,
                })
              end,
            })
          else
            -- Fallback: se[48;65;170;1950;2380ttup servers manually if setup_handlers doesn't exist
            local servers = { 'ts_ls', 'pyright', 'bashls', 'html', 'cssls', 'emmet_ls' }
            for _, server in ipairs(servers) do
              if server == 'emmet_ls' then
                lspconfig[server].setup({
                  capabilities = capabilities,
                  filetypes = { 'html', 'css', 'scss', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
                })
              else
                lspconfig[server].setup({
                  capabilities = capabilities,
                })
              end
            end
          end
        end, 100) -- Small delay to ensure everything is loaded

        -- Completion setup
        local cmp = require('cmp')
        local luasnip = require('luasnip')

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ['<Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
          }),
          sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
          }, {
            { name = 'buffer' },
            { name = 'path' },
          })
        })

        -- LSP key mappings
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            local opts = { buffer = ev.buf }

            -- Navigation
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)

            -- Information
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)

            -- Actions
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
            vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', '<leader>f', function()
              vim.lsp.buf.format { async = true }
            end, opts)

            -- Diagnostics (FIXED: Updated for newer Neovim versions)
            vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
            vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, opts)
            vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, opts)
            vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

            -- Workspace management
            vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
            vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
            vim.keymap.set('n', '<leader>wl', function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, opts)
          end,
        })
      end
    },
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
      'nvim-telescope/telescope.nvim',
      branch = '0.1.x',
      dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {
      "preservim/nerdcommenter",
      lazy = false,
      config = function()
        vim.g.NERDCreateDefaultMappings = 1
        vim.g.NERDCommentEmptyLines = 1
        vim.g.NERDSpaceDelims = 1
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
          -- FIXED: Simplified hooks without problematic plugins
          hooks = {
            before_save = function(_)  -- FIXED: Use underscore for unused parameter
              -- Close terminal buffers before saving
              for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(bufnr) then
                  local buftype = vim.bo[bufnr].buftype
                  local bufname = vim.api.nvim_buf_get_name(bufnr)

                  if buftype == 'terminal' or bufname:match('term://') or bufname:match('toggleterm') then
                    -- Mark as unmodified and force delete
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
            before_load = function(_)  -- FIXED: Use underscore for unused parameter
              -- Close any existing terminals before loading
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
          },
          -- FIXED: Disable problematic plugins
          plugins = {
            close_windows = false,  -- Disable the problematic close_windows plugin
            delete_hidden_buffers = false,  -- Disable this too to avoid issues
          },
        }
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
          current_line_blame = true,
          current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol',
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
          direction = 'horizontal',
          close_on_exit = true,
          shell = vim.o.shell,
          auto_scroll = true,
          -- FIXED: Handle terminal cleanup properly
          on_create = function(_)
            vim.opt_local.scrolloff = 0
            vim.opt_local.sidescrolloff = 0
          end,
          on_close = function(term)
            -- Force close without asking about unsaved changes
            vim.bo[term.bufnr].buftype = 'nofile'
            vim.bo[term.bufnr].modified = false
          end,
          float_opts = {
            border = 'curved',
            winblend = 0,
            highlights = {
              border = "Normal",
              background = "Normal",
            }
          }
        })

        -- FIXED: Better terminal keymaps with proper cleanup
        function _G.set_terminal_keymaps()
          local opts = {buffer = 0, noremap = true, silent = true}
          -- Exit terminal mode
          vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
          vim.keymap.set('t', '<C-c>', [[<C-\><C-n>]], opts)
          -- Window navigation from terminal
          vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
          vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
          vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
          vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
          -- Easy return to terminal mode
          vim.keymap.set('n', 'i', 'i', {buffer = 0})
          vim.keymap.set('n', 'a', 'a', {buffer = 0})
          -- Force close terminal without confirmation
          vim.keymap.set('n', 'q', function()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.bo[bufnr].modified = false
            vim.cmd('close')
          end, {buffer = 0, desc = 'Close terminal'})
        end

        -- Apply keymaps when terminal opens
        vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

        -- FIXED: Auto-cleanup terminal buffers to prevent unsaved changes errors
        vim.api.nvim_create_autocmd("TermClose", {
          callback = function(args)
            local bufnr = args.buf
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.bo[bufnr].modified = false
              vim.bo[bufnr].buftype = 'nofile'
            end
          end,
        })

        -- Additional terminal management
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

        -- Enhanced terminal keymaps
        vim.keymap.set('n', '<leader>tf', '<cmd>lua _FLOAT_TOGGLE()<CR>', { desc = 'Toggle floating terminal' })

        -- Manual terminal toggle with insert mode (FIXED: explicitly set horizontal)
        vim.keymap.set('n', '<leader>tt', function()
          vim.cmd('ToggleTerm direction=horizontal')
          -- Small delay then enter insert mode
          vim.defer_fn(function()
            if vim.bo.buftype == 'terminal' then
              vim.cmd('startinsert')
            end
          end, 50)
        end, { desc = 'Toggle horizontal terminal and enter insert mode' })

        -- Quick horizontal and vertical terminals
        vim.keymap.set('n', '<leader>th', '<cmd>ToggleTerm direction=horizontal<CR>', { desc = 'Toggle horizontal terminal' })
        vim.keymap.set('n', '<leader>tv', '<cmd>ToggleTerm direction=vertical<CR>', { desc = 'Toggle vertical terminal' })
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
            custom_filter = function(buf_number, _)
              local buf_name = vim.api.nvim_buf_get_name(buf_number)
              local buf_ft = vim.bo[buf_number].filetype

              if buf_ft == "NvimTree" then
                return false
              end

              if vim.fn.isdirectory(buf_name) == 1 then
                return false
              end

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
        vim.g.undotree_WindowLayout = 2
        vim.g.undotree_ShortIndicators = 1
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.keymap.set('n', '<leader>u', ':UndotreeToggle<CR>', { desc = 'Toggle undo tree' })
      end
    },
    {
      'catppuccin/nvim',
      name = 'catppuccin',
      priority = 1000,
      config = function()
        require('catppuccin').setup({
          flavour = 'mocha',
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
    {
      'pmizio/typescript-tools.nvim',
      dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
      ft = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
      config = function()
        require('typescript-tools').setup({
          settings = {
            separate_diagnostic_server = true,
            publish_diagnostic_on = 'insert_leave',
            expose_as_code_action = {},
            tsserver_path = nil,
            tsserver_plugins = {},
            tsserver_max_memory = 'auto',
            tsserver_format_options = {},
            tsserver_file_preferences = {},
          },
        })
      end
    },
    {
      'mattn/emmet-vim',
      ft = { 'html', 'css', 'scss', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
      config = function()
        vim.g.user_emmet_leader_key = '<C-Z>'
        vim.g.user_emmet_settings = {
          javascript = {
            extends = 'jsx',
          },
          typescript = {
            extends = 'tsx',
          },
        }
      end
    },
    {
      'norcalli/nvim-colorizer.lua',
      ft = { 'css', 'scss', 'html', 'javascript', 'typescript' },
      config = function()
        require('colorizer').setup({
          'css',
          'scss',
          'html',
          'javascript',
          'typescript',
        }, {
          RGB = true,
          RRGGBB = true,
          names = false,
          RRGGBBAA = true,
          rgb_fn = true,
          hsl_fn = true,
          css = true,
          css_fn = true,
        })
      end
    },
    {
      'linux-cultist/venv-selector.nvim',
      ft = 'python',
      dependencies = {
        'neovim/nvim-lspconfig',
        'nvim-telescope/telescope.nvim',
        'mfussenegger/nvim-dap-python'
      },
      config = function()
        require('venv-selector').setup({
          name = {
            'venv',
            '.venv',
            'env',
            '.env',
          },
        })
        vim.keymap.set('n', '<leader>vs', '<cmd>VenvSelect<cr>', { desc = 'Select Python venv' })
      end
    },
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        },
      },
    },
    { 'Bilal2453/luvit-meta', lazy = true },
    {
      'b0o/schemastore.nvim',
      ft = 'json',
      config = function()
        require('lspconfig').jsonls.setup({
          settings = {
            json = {
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        })
      end
    },
    {
      'vuki656/package-info.nvim',
      ft = 'json',
      dependencies = { 'MunifTanjim/nui.nvim' },
      config = function()
        require('package-info').setup({
          colors = {
            up_to_date = '#3C4048',
            outdated = '#d19a66',
          },
          icons = {
            enable = true,
            style = {
              up_to_date = '|  ',
              outdated = '|  ',
            },
          },
        })

        vim.keymap.set('n', '<leader>ns', require('package-info').show, { desc = 'Show package info' })
        vim.keymap.set('n', '<leader>nc', require('package-info').hide, { desc = 'Hide package info' })
        vim.keymap.set('n', '<leader>nt', require('package-info').toggle, { desc = 'Toggle package info' })
        vim.keymap.set('n', '<leader>nu', require('package-info').update, { desc = 'Update package' })
        vim.keymap.set('n', '<leader>nd', require('package-info').delete, { desc = 'Delete package' })
        vim.keymap.set('n', '<leader>ni', require('package-info').install, { desc = 'Install package' })
        vim.keymap.set('n', '<leader>np', require('package-info').change_version, { desc = 'Change package version' })
      end
    }
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})

-- FIXED: Clean diagnostic configuration without special characters
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    source = "if_many",
    format = function(diagnostic)
      -- Hide trailing space diagnostics entirely
      if diagnostic.message and diagnostic.message:lower():match("trailing") then
        return nil
      end

      -- Robust duplicate prevention system
      local key = string.format("%d:%d:%s",
        diagnostic.lnum,
        diagnostic.col,
        diagnostic.message
      )

      -- Initialize global tracking
      if not _G.diagnostic_tracker then
        _G.diagnostic_tracker = {
          seen = {},
          buffer_generation = {}
        }
      end

      local bufnr = vim.api.nvim_get_current_buf()

      -- Create buffer-specific key
      local buffer_key = bufnr .. ":" .. key

      -- Check if we've seen this exact diagnostic in this buffer generation
      if _G.diagnostic_tracker.seen[buffer_key] then
        return nil -- Hide duplicate
      end

      -- Mark as seen
      _G.diagnostic_tracker.seen[buffer_key] = true

      return diagnostic.message
    end,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
})

-- Clear duplicate tracking when diagnostics are refreshed
vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost", "LspAttach"}, {
  callback = function(args)
    if not _G.diagnostic_tracker then
      _G.diagnostic_tracker = { seen = {}, buffer_generation = {} }
    end

    local bufnr = args.buf or vim.api.nvim_get_current_buf()

    -- Increment buffer generation to invalidate old tracking
    _G.diagnostic_tracker.buffer_generation[bufnr] =
      (_G.diagnostic_tracker.buffer_generation[bufnr] or 0) + 1

    -- Clear old entries for this buffer
    for key, _ in pairs(_G.diagnostic_tracker.seen) do
      if key:match("^" .. bufnr .. ":") then
        _G.diagnostic_tracker.seen[key] = nil
      end
    end
  end,
})

-- Auto-remove trailing spaces on save instead of showing warnings
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

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

-- Buffer navigation with Alt+Tab
vim.keymap.set('n', '<M-Tab>', ':BufferLineCycleNext<CR>', { noremap = true, silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<M-S-Tab>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc = 'Previous buffer' })

-- Create custom LSP commands since they don't exist by default
vim.api.nvim_create_user_command('LspInfo', function()
  local clients = vim.lsp.get_clients()  -- FIXED: Updated from get_active_clients()
  if #clients == 0 then
    print("No active LSP clients")
    return
  end

  for _, client in ipairs(clients) do
    print(string.format("%s (id: %d)", client.name, client.id))
  end
end, { desc = 'Show LSP client info' })

vim.api.nvim_create_user_command('LspRestart', function()
  local clients = vim.lsp.get_clients()  -- FIXED: Updated from get_active_clients()
  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id)
  end
  vim.defer_fn(function()
    vim.cmd('edit')
  end, 100)
end, { desc = 'Restart LSP clients' })

-- LSP keymaps
vim.keymap.set('n', '<leader>li', '<cmd>LspInfo<cr>', { desc = 'LSP Info' })
vim.keymap.set('n', '<leader>lr', '<cmd>LspRestart<cr>', { desc = 'LSP Restart' })
vim.keymap.set('n', '<leader>ma', '<cmd>Mason<cr>', { desc = 'Open Mason' })

-- Use spaces instead of tabs
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.wrap = false
vim.opt.mouse = 'a'
vim.opt.hidden = true

-- Disable swapfiles
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Show line numbers
vim.opt.number = true

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

-- Auto-save buffers
vim.api.nvim_create_autocmd({"FocusLost", "BufLeave", "CursorHold", "CursorHoldI"}, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command('silent! write')
    end
  end,
})

-- Enable persistent undo
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'
vim.opt.undolevels = 10000
vim.opt.undoreload = 10000

-- Simple function to copy diagnostic error under cursor
local function copy_diagnostic_under_cursor()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })

  if #diagnostics == 0 then
    print("No diagnostic at cursor")
    return
  end

  local message = diagnostics[1].message
  vim.fn.setreg('+', message)
  vim.fn.setreg('"', message)
  print("Copied: " .. (message:len() > 50 and message:sub(1, 50) .. "..." or message))
end

vim.keymap.set('n', '<leader>cd', copy_diagnostic_under_cursor, { desc = 'Copy diagnostic under cursor' })

-- Copy all diagnostics on current line
local function copy_all_diagnostics_on_line()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })

  if #diagnostics == 0 then
    print("No diagnostics on current line")
    return
  end

  local messages = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, diagnostic.message)
  end

  local combined = table.concat(messages, ' | ')
  vim.fn.setreg('+', combined)
  vim.fn.setreg('"', combined)
  print("Copied " .. #diagnostics .. " diagnostic(s)")
end

vim.keymap.set('n', '<leader>cD', copy_all_diagnostics_on_line, { desc = 'Copy all diagnostics on line' })

-- Copy messages to clipboard
local function copy_last_message()
  local messages = vim.fn.execute('messages')
  vim.fn.setreg('+', messages)
  print("Messages copied to clipboard")
end

vim.keymap.set('n', '<leader>cm', copy_last_message, { desc = 'Copy messages to clipboard' })

-- ADDED: Clipboard operations using + register
-- Yank operations
vim.keymap.set('n', '<leader>y', '"+y', { desc = 'Yank to clipboard' })
vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Yank to clipboard' })
vim.keymap.set('n', '<leader>yy', '"+yy', { desc = 'Yank line to clipboard' })

-- Delete operations (cut to clipboard)
vim.keymap.set('n', '<leader>d', '"+d', { desc = 'Delete to clipboard' })
vim.keymap.set('v', '<leader>d', '"+d', { desc = 'Delete to clipboard' })
vim.keymap.set('n', '<leader>dd', '"+dd', { desc = 'Delete line to clipboard' })

-- Paste operations
vim.keymap.set('n', '<leader>p', '"+p', { desc = 'Paste from clipboard after cursor' })
vim.keymap.set('n', '<leader>P', '"+P', { desc = 'Paste from clipboard before cursor' })
vim.keymap.set('v', '<leader>p', '"+p', { desc = 'Paste from clipboard' })
