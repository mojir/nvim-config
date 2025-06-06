-- Fixed terminal.lua configuration
return {
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
        insert_mappings = false,
        persist_size = true,
        direction = 'horizontal',
        close_on_exit = true,
        shell = vim.o.shell,
        auto_scroll = true,
        on_create = function(_)
          vim.opt_local.scrolloff = 0
          vim.opt_local.sidescrolloff = 0
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

      function _G.set_terminal_keymaps()
        local opts = {buffer = 0, noremap = true, silent = true}
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-c>', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        vim.keymap.set('n', 'i', 'i', {buffer = 0})
        vim.keymap.set('n', 'a', 'a', {buffer = 0})
        vim.keymap.set('n', 'q', function()
          local bufnr = vim.api.nvim_get_current_buf()
          if vim.api.nvim_buf_is_valid(bufnr) then
            vim.bo[bufnr].modified = false
          end
          vim.cmd('close')
        end, {buffer = 0, desc = 'Close terminal'})
      end

      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

      -- Fixed TermClose autocmd with proper error handling
      vim.api.nvim_create_autocmd("TermClose", {
        callback = function(args)
          local bufnr = args.buf
          -- Check if buffer is valid before trying to modify it
          if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
            -- Use pcall to safely set buffer options
            pcall(function()
              vim.bo[bufnr].modified = false
              vim.bo[bufnr].buftype = 'nofile'
            end)
          end
        end,
      })

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

      vim.keymap.set('n', '<leader>tt', function()
        vim.cmd('ToggleTerm direction=horizontal')
        vim.defer_fn(function()
          if vim.bo.buftype == 'terminal' then
            vim.cmd('startinsert')
          end
        end, 50)
      end, { desc = 'Toggle horizontal terminal and enter insert mode' })

      vim.keymap.set('n', '<leader>th', '<cmd>ToggleTerm direction=horizontal<CR>', { desc = 'Toggle horizontal terminal' })
      vim.keymap.set('n', '<leader>tv', '<cmd>ToggleTerm direction=vertical<CR>', { desc = 'Toggle vertical terminal' })
    end
  },
}
