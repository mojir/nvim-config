-- lua/plugins/diffview.lua
return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('diffview').setup({
        view = {
          merge_tool = {
            layout = "diff3_horizontal",  -- 3-way merge: LOCAL | BASE | REMOTE
          },
        },
      })
      
      -- Essential keymaps
      vim.keymap.set('n', '<leader>gdo', '<cmd>DiffviewOpen<cr>', { desc = 'Open diffview' })
      vim.keymap.set('n', '<leader>gdc', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' })
      vim.keymap.set('n', '<leader>gdh', '<cmd>DiffviewFileHistory<cr>', { desc = 'File history' })
      vim.keymap.set('n', '<leader>gdH', '<cmd>DiffviewFileHistory %<cr>', { desc = 'Current file history' })
    end
  }
}
