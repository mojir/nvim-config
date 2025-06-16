return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    config = function()
      require("typescript-tools").setup({
        settings = {
          separate_diagnostic_server = true,
          publish_diagnostic_on = "insert_leave",
          expose_as_code_action = {},
          tsserver_path = nil,
          tsserver_plugins = {},
          tsserver_max_memory = "auto",
          tsserver_format_options = {},
          tsserver_file_preferences = {},
        },
      })
      -- Add to the config function in typescript.lua
      -- vim.keymap.set('n', '<leader>to', '<cmd>TSToolsOrganizeImports<cr>', { desc = 'Organize imports' })
      -- vim.keymap.set('n', '<leader>tu', '<cmd>TSToolsRemoveUnused<cr>', { desc = 'Remove unused imports' })
      -- vim.keymap.set('n', '<leader>tf', '<cmd>TSToolsFixAll<cr>', { desc = 'Fix all issues' })
      -- vim.keymap.set('n', '<leader>tr', '<cmd>TSToolsRenameFile<cr>', { desc = 'Rename file' })
    end,
  },
}
