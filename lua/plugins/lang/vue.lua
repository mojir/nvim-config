-- Create: lua/plugins/lang/vue.lua

return {
  -- Vue Language Server
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Vue Language Server setup
      -- Vue Language Server setup (Volar v2.0+ with Hybrid mode)
      local mason_registry = require('mason-registry')
      local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() 
        .. '/node_modules/@vue/language-server'

      lspconfig.volar.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Disable Volar's formatting since we're using ESLint
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
        filetypes = { 'vue' },
      })

      -- TypeScript support for Vue (with Vue TypeScript plugin)
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Disable formatting for both JS/TS and Vue files
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
        init_options = {
          plugins = {
            {
              name = '@vue/typescript-plugin',
              location = vue_language_server_path,
              languages = { 'vue' },
            },
          },
        },
        filetypes = { 
          'javascript', 
          'javascriptreact', 
          'typescript', 
          'typescriptreact',
          'vue'  -- Add Vue support to TypeScript server
        },
      })
    end
  },

  -- Vue syntax highlighting and more
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      -- Ensure Vue parser is installed
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'vue' })
    end,
  },
}
