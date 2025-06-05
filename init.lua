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

        -- Mason-lspconfig setup (FIXED: removed automatic_enable)
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
          automatic_installation = true,
        })

        local lspconfig = require('lspconfig')
        local cmp_nvim_lsp = require('cmp_nvim_lsp')
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- Lua server (FIXED: added trailing space disable)
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

        -- TypeScript/JavaScript server
        lspconfig.ts_ls.setup({
          capabilities = capabilities,
        })

        -- Python server
        lspconfig.pyright.setup({
          capabilities = capabilities,
        })

        -- Bash server
        lspconfig.bashls.setup({
          capabilities = capabilities,
        })

        -- HTML server
        lspconfig.html.setup({
          capabilities = capabilities,
        })

        -- CSS server
        lspconfig.cssls.setup({
          capabilities = capabilities,
        })

        -- Emmet server
        lspconfig.emmet_ls.setup({
          capabilities = capabilities,
          filetypes = { 'html', 'css', 'scss', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
        })

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

            -- Diagnostics
            vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
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
          float_opts = {
            border = 'curved',
            winblend = 0,
            highlights = {
              border = "Normal",
              background = "Normal",
            }
          }
        })

        function _G.set_terminal_keymaps()
          local opts = {buffer = 0}
          vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
          vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
          vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
          vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
          vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        end

        vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

        local Terminal = require('toggleterm.terminal').Terminal
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
    -- FIXED: Removed duplicate bufferline - keeping only the enhanced version
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
            custom_filter = function(buf_number, buf_numbers)
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

-- FIXED: Enhanced diagnostic configuration to prevent duplicates
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    source = "if_many",
    format = function(diagnostic)
      -- Hide trailing space diagnostics entirely
      if diagnostic.message and diagnostic.message:lower():match("trailing") then
        return nil
      end
      return diagnostic.message
    end,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    source = "if_many",
    format = function(diagnostic)
      if diagnostic.message and diagnostic.message:lower():match("trailing") then
        return nil
      end
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

-- FIXED: Create custom LSP commands since they don't exist by default
vim.api.nvim_create_user_command('LspInfo', function()
  local clients = vim.lsp.get_active_clients()
  if #clients == 0 then
    print("No active LSP clients")
    return
  end

  for _, client in ipairs(clients) do
    print(string.format("%s (id: %d)", client.name, client.id))
  end
end, { desc = 'Show LSP client info' })

vim.api.nvim_create_user_command('LspRestart', function()
  local clients = vim.lsp.get_active_clients()
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

  -- Get the first diagnostic message
  local message = diagnostics[1].message

  -- Copy to system clipboard
  vim.fn.setreg('+', message)

  -- Also copy to default register (for pasting with 'p')
  vim.fn.setreg('"', message)

  -- Show confirmation
  print("Copied: " .. (message:len() > 50 and message:sub(1, 50) .. "..." or message))
end

-- Add keymap - you can change <leader>cd to whatever you prefer
vim.keymap.set('n', '<leader>cd', copy_diagnostic_under_cursor, { desc = 'Copy diagnostic under cursor' })

-- Alternative: Copy all diagnostics on current line (if multiple exist)
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

-- Optional: Alternative keymap for copying all diagnostics on line
vim.keymap.set('n', '<leader>cD', copy_all_diagnostics_on_line, { desc = 'Copy all diagnostics on line' })

local function copy_last_message()
  local messages = vim.fn.execute('messages')
  vim.fn.setreg('+', messages)  -- Copy all messages to clipboard
  print("Messages copied to clipboard")
end

vim.keymap.set('n', '<leader>cm', copy_last_message, { desc = 'Copy messages to clipboard' })


-- Simple Diagnostic Analyzer - Add this to your init.lua

local function analyze_diagnostics_on_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.fn.line('.') - 1

  print("=== DIAGNOSTIC ANALYSIS ===")
  print("Buffer: " .. bufnr .. " | Line: " .. (line + 1))
  print()

  -- Get all diagnostics for current line
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })

  if #diagnostics == 0 then
    print("❌ No diagnostics on current line")
    return
  end

  print("📊 Found " .. #diagnostics .. " diagnostic(s) on this line:")
  print()

  -- Analyze each diagnostic in detail
  for i, diag in ipairs(diagnostics) do
    print(string.format("🔍 Diagnostic #%d:", i))
    print("   Message: '" .. diag.message .. "'")
    print("   Source: " .. (diag.source or "❓ UNKNOWN"))
    print("   Severity: " .. vim.diagnostic.severity[diag.severity])
    print("   Namespace ID: " .. diag.namespace)

    -- Get namespace name
    local ns_info = vim.diagnostic.get_namespace(diag.namespace)
    print("   Namespace Name: " .. (ns_info.name or "unnamed"))

    print("   Code: " .. (diag.code or "none"))
    print("   Column: " .. diag.col)
    if diag.user_data then
      print("   User Data: " .. vim.inspect(diag.user_data))
    end
    print()
  end

  -- Check for exact duplicates
  print("🔎 DUPLICATE ANALYSIS:")
  local seen = {}
  local duplicates_found = false

  for i, diag in ipairs(diagnostics) do
    local key = diag.message .. "|" .. (diag.source or "no-source")

    if seen[key] then
      print(string.format("   🔴 Diagnostic #%d is DUPLICATE of #%d", i, seen[key]))
      print(string.format("      Both have message: '%s'", diag.message))
      duplicates_found = true
    else
      seen[key] = i
    end
  end

  if not duplicates_found then
    print("   ✅ No exact duplicates found")
  end

  print()
  print("🖥️  LSP CLIENT ANALYSIS:")

  -- Check which LSP clients are active
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  print("   Active LSP clients: " .. #clients)

  for _, client in ipairs(clients) do
    print(string.format("   📡 %s (id: %d)", client.name, client.id))

    -- Check if client provides diagnostics
    if client.server_capabilities then
      local diagnostic_provider = client.server_capabilities.diagnosticProvider
      if diagnostic_provider then
        print("      ✅ Provides diagnostics")
        if type(diagnostic_provider) == "table" then
          print("      Details: " .. vim.inspect(diagnostic_provider))
        end
      else
        print("      ❌ No diagnostic provider")
      end
    end
  end

  print()
  print("🔢 NAMESPACE BREAKDOWN:")

  -- Group diagnostics by namespace
  local ns_groups = {}
  for _, diag in ipairs(diagnostics) do
    local ns = diag.namespace
    if not ns_groups[ns] then
      local ns_info = vim.diagnostic.get_namespace(ns)
      ns_groups[ns] = {
        count = 0,
        name = ns_info.name or "unnamed",
        messages = {}
      }
    end
    ns_groups[ns].count = ns_groups[ns].count + 1
    table.insert(ns_groups[ns].messages, diag.message)
  end

  for ns_id, info in pairs(ns_groups) do
    print(string.format("   Namespace %d ('%s'): %d diagnostic(s)", ns_id, info.name, info.count))
    for j, msg in ipairs(info.messages) do
      print(string.format("      %d. %s", j, msg))
    end
  end

  print()
  print("=== END ANALYSIS ===")
end

-- Add keymap to trigger analysis
vim.keymap.set('n', '<leader>da', analyze_diagnostics_on_line, { desc = 'Analyze diagnostics on current line' })

-- Quick function to analyze ALL diagnostics in buffer
local function analyze_all_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local all_diagnostics = vim.diagnostic.get(bufnr)

  print("=== BUFFER DIAGNOSTIC OVERVIEW ===")
  print("Total diagnostics in buffer: " .. #all_diagnostics)

  -- Group by message to find duplicates
  local message_counts = {}
  local line_counts = {}

  for _, diag in ipairs(all_diagnostics) do
    local msg = diag.message
    local line = diag.lnum + 1

    message_counts[msg] = (message_counts[msg] or 0) + 1
    line_counts[line] = (line_counts[line] or 0) + 1
  end

  print("\n📊 DUPLICATE MESSAGES ACROSS BUFFER:")
  local found_buffer_dupes = false
  for msg, count in pairs(message_counts) do
    if count > 1 then
      print(string.format("   🔴 '%s' appears %d times", msg:sub(1, 60), count))
      found_buffer_dupes = true
    end
  end

  if not found_buffer_dupes then
    print("   ✅ No duplicate messages across buffer")
  end

  print("\n📍 LINES WITH MULTIPLE DIAGNOSTICS:")
  for line, count in pairs(line_counts) do
    if count > 1 then
      print(string.format("   Line %d: %d diagnostics", line, count))
    end
  end

  print("=== END BUFFER ANALYSIS ===")
end

vim.keymap.set('n', '<leader>dA', analyze_all_diagnostics, { desc = 'Analyze all diagnostics in buffer' })

-- Function to monitor diagnostic changes in real-time
local function start_diagnostic_monitoring()
  print("🔍 Starting diagnostic monitoring...")
  print("Any diagnostic changes will be logged below:")

  local original_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    if result and result.diagnostics then
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      print(string.format("📡 %s published %d diagnostics", client.name, #result.diagnostics))

      -- Check for duplicate messages in this publication
      local msg_counts = {}
      for _, diag in ipairs(result.diagnostics) do
        local msg = diag.message
        msg_counts[msg] = (msg_counts[msg] or 0) + 1
      end

      for msg, count in pairs(msg_counts) do
        if count > 1 then
          print(string.format("   ⚠️  Duplicate in publication: '%s' (x%d)", msg:sub(1, 40), count))
        end
      end
    end

    return original_handler(err, result, ctx, config)
  end

  print("✅ Monitoring active. Use <leader>dm to stop.")
end

local function stop_diagnostic_monitoring()
  print("🛑 Stopping diagnostic monitoring...")
  -- This would require storing the original handler, simplified for demo
  print("Restart Neovim to fully reset handlers")
end

vim.keymap.set('n', '<leader>dm', start_diagnostic_monitoring, { desc = 'Monitor diagnostic publications' })

-- Based on your user_data, let's do targeted analysis

local function analyze_deprecated_duplicates()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.fn.line('.') - 1

  print("=== TARGETED DUPLICATE ANALYSIS ===")
  print("Looking for 'Deprecated' message duplicates...")
  print()

  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
  local deprecated_diags = {}

  -- Find all "Deprecated" diagnostics
  for i, diag in ipairs(diagnostics) do
    if diag.message and diag.message:match("Deprecated") then
      table.insert(deprecated_diags, {index = i, diag = diag})
    end
  end

  print("Found " .. #deprecated_diags .. " 'Deprecated' diagnostics:")
  print()

  for _, item in ipairs(deprecated_diags) do
    local diag = item.diag
    print(string.format("🔍 Deprecated Diagnostic #%d:", item.index))
    print("   Source: " .. (diag.source or "UNKNOWN"))
    print("   Namespace: " .. diag.namespace)

    local ns_info = vim.diagnostic.get_namespace(diag.namespace)
    print("   Namespace Name: " .. (ns_info.name or "unnamed"))

    -- Analyze the user_data
    if diag.user_data and diag.user_data.lsp then
      print("   LSP Data:")
      print("     LSP Source: " .. (diag.user_data.lsp.source or "none"))
      print("     LSP Code: " .. (diag.user_data.lsp.code or "none"))
      if diag.user_data.lsp.range then
        local range = diag.user_data.lsp.range
        print(string.format("     LSP Range: line %d, char %d-%d",
          range.start.line, range.start.character, range["end"].character))
      end
    else
      print("   ❌ No LSP user_data")
    end
    print()
  end

  -- Check if these are truly identical
  if #deprecated_diags > 1 then
    print("🔎 COMPARING DUPLICATES:")
    local first = deprecated_diags[1].diag

    for i = 2, #deprecated_diags do
      local current = deprecated_diags[i].diag
      print(string.format("Comparing #1 vs #%d:", deprecated_diags[i].index))

      -- Compare key fields
      local same_message = first.message == current.message
      local same_source = (first.source or "") == (current.source or "")
      local same_namespace = first.namespace == current.namespace
      local same_position = (first.lnum == current.lnum and first.col == current.col)

      print("   Same message: " .. (same_message and "✅" or "❌"))
      print("   Same source: " .. (same_source and "✅" or "❌"))
      print("   Same namespace: " .. (same_namespace and "✅" or "❌"))
      print("   Same position: " .. (same_position and "✅" or "❌"))

      if same_message and same_position and not same_namespace then
        print("   🔴 LIKELY DUPLICATE: Different namespaces, same content!")
      end
      print()
    end
  end

  -- Check active LSP clients that might be involved
  print("🖥️  RELEVANT LSP CLIENTS:")
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })

  for _, client in ipairs(clients) do
    if client.name:lower():match("lua") or client.name:lower():match("diagnostic") then
      print(string.format("   🎯 %s (id: %d) - LIKELY RELEVANT", client.name, client.id))
    else
      print(string.format("   📡 %s (id: %d)", client.name, client.id))
    end
  end

  print()
  print("=== RECOMMENDATIONS ===")

  if #deprecated_diags > 1 then
    print("🔧 You have duplicate 'Deprecated' diagnostics. Likely causes:")
    print("   1. Multiple LSP clients analyzing the same Lua code")
    print("   2. lua_ls + another Lua linter/diagnostic tool")
    print("   3. Multiple instances of the same LSP client")
    print()
    print("💡 Next steps:")
    print("   1. Check :Mason for multiple Lua tools")
    print("   2. Look for conflicting LSP setups in your config")
    print("   3. Consider disabling 'deprecated' warnings in lua_ls")
  else
    print("✅ No duplicate 'Deprecated' diagnostics found")
  end

  print("=== END ANALYSIS ===")
end

-- Check what LSP servers are installed via Mason
local function check_mason_lua_tools()
  print("=== MASON INSTALLED PACKAGES ===")

  -- Try to get Mason registry
  local has_mason, mason_registry = pcall(require, "mason-registry")

  if not has_mason then
    print("❌ Mason not available")
    return
  end

  local installed = mason_registry.get_installed_packages()
  print("Installed packages that might affect Lua diagnostics:")

  for _, pkg in ipairs(installed) do
    local name = pkg.name
    if name:lower():match("lua") or name:lower():match("diagnostic") or name:lower():match("lint") then
      print("   🎯 " .. name .. " - RELEVANT")
    end
  end

  -- Check specifically for lua_ls
  if mason_registry.is_installed("lua_ls") then
    print("   ✅ lua_ls is installed")
  else
    print("   ❌ lua_ls not found in Mason")
  end

  print("=== END MASON CHECK ===")
end

-- Check your LSP configuration for potential conflicts
local function check_lsp_config_conflicts()
  print("=== LSP CONFIGURATION ANALYSIS ===")

  -- Check if lua_ls is configured multiple times
  local lua_configs = 0

  -- This is a simplified check - in reality we'd need to inspect your actual config
  print("💡 Manual checks needed:")
  print("   1. Search your config for 'lua_ls' - should appear only once")
  print("   2. Check for 'lspconfig.lua_ls.setup' - should be called only once")
  print("   3. Look for any null-ls or nvim-lint Lua configurations")
  print("   4. Check if you have any standalone Lua diagnostic tools")

  print("=== END CONFIG ANALYSIS ===")
end

-- Comprehensive diagnostic tracker
local function track_diagnostic_sources()
  print("=== DIAGNOSTIC SOURCE TRACKER ===")
  print("This will monitor where diagnostics come from...")

  -- Hook into the diagnostic system
  local original_set = vim.diagnostic.set
  vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
    local ns_info = vim.diagnostic.get_namespace(namespace)
    local ns_name = ns_info.name or ("namespace_" .. namespace)

    -- Count deprecated messages
    local deprecated_count = 0
    for _, diag in ipairs(diagnostics or {}) do
      if diag.message and diag.message:match("Deprecated") then
        deprecated_count = deprecated_count + 1
      end
    end

    if deprecated_count > 0 then
      print(string.format("📊 Namespace '%s' (%d) set %d 'Deprecated' diagnostic(s)",
        ns_name, namespace, deprecated_count))
    end

    return original_set(namespace, bufnr, diagnostics, opts)
  end

  print("✅ Tracking active. Edit your file to see diagnostic sources.")
  print("Use :lua vim.diagnostic.set = original_set to stop tracking")
end

-- Add keymaps
vim.keymap.set('n', '<leader>dt', analyze_deprecated_duplicates, { desc = 'Analyze deprecated duplicates' })
vim.keymap.set('n', '<leader>dm', check_mason_lua_tools, { desc = 'Check Mason Lua tools' })
vim.keymap.set('n', '<leader>dc', check_lsp_config_conflicts, { desc = 'Check LSP config conflicts' })
vim.keymap.set('n', '<leader>ds', track_diagnostic_sources, { desc = 'Track diagnostic sources' })
