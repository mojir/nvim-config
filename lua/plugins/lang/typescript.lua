return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    config = function()
      require("typescript-tools").setup({
        capabilities = vim.tbl_deep_extend("force", 
          require("cmp_nvim_lsp").default_capabilities(),
          {
            -- Explicitly enable symbol providers
            documentSymbolProvider = true,
            workspaceSymbolProvider = true,
          }
        ),
        settings = {
          separate_diagnostic_server = true,
          publish_diagnostic_on = "insert_leave",
          tsserver_file_preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsWithInsertText = true,
          },
        },
      })
    end,
  },
}
