return {
  -- Emmet for HTML/CSS
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

  -- Color highlighting
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

  -- Package.json info
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
}
