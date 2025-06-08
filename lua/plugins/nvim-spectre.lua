-- lua/plugins/spectre.lua
return {
  {
    'nvim-pack/nvim-spectre',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('spectre').setup()

      -- Essential keymaps
      vim.keymap.set('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', { desc = "Toggle Spectre" })
      vim.keymap.set('v', '<leader>S', '<esc><cmd>lua require("spectre").open_visual()<CR>', { desc = "Search selection" })

      vim.keymap.set('n', '<leader>sb', '<cmd>lua require("spectre").open_file_search()<CR>', { desc = "Search/replace in current buffer" })
      vim.keymap.set('v', '<leader>sb', '<esc><cmd>lua require("spectre").open_file_search()<CR>', { desc = "Search selection in current buffer" })

    end,
  }
}
