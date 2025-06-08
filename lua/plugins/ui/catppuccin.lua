return {
  -- Colorscheme
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
  }
}

