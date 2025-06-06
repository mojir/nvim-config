return {
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
}
