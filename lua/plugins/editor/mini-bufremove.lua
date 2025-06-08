return {
  -- Add to your plugins/editor.lua or create plugins/mini.lua
  {
    'echasnovski/mini.bufremove',
    config = function()
      require('mini.bufremove').setup()

      -- Replace your existing <leader>bd mapping
      vim.keymap.set('n', '<leader>bd', function()
        require('mini.bufremove').delete(0, false)
      end, { desc = 'Delete buffer (smart)' })

      -- Optional: Force delete (ignores unsaved changes)
      vim.keymap.set('n', '<leader>bD', function()
        require('mini.bufremove').delete(0, true)
      end, { desc = 'Delete buffer (force)' })
    end
  }
}

