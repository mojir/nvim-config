-- Basic yanky.nvim configuration
-- Add this to your plugins/ directory (e.g., lua/plugins/yanky.lua)

return {
  {
    'gbprod/yanky.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('yanky').setup({
        ring = {
          history_length = 50,
          storage = "shada",
          sync_with_numbered_registers = true,
        },
        system_clipboard = {
          sync_with_ring = true,
        },
        highlight = {
          on_put = true,
          on_yank = true,
          timer = 500,
        },
        preserve_cursor_position = {
          enabled = true,
        },
      })

      -- Load telescope extension
      require('telescope').load_extension('yank_history')

      -- Basic keymaps
      vim.keymap.set({"n","x"}, "p", "<Plug>(YankyPutAfter)", { desc = 'Put after' })
      vim.keymap.set({"n","x"}, "P", "<Plug>(YankyPutBefore)", { desc = 'Put before' })
      
      -- Cycle through yank history after pasting
      vim.keymap.set("n", "<C-p>", "<Plug>(YankyPreviousEntry)", { desc = 'Previous yank' })
      vim.keymap.set("n", "<C-n>", "<Plug>(YankyNextEntry)", { desc = 'Next yank' })

      -- Open yank history in Telescope
      vim.keymap.set('n', '<leader>fy', '<cmd>Telescope yank_history<cr>', { desc = 'Yank history' })
    end,
  },
}
