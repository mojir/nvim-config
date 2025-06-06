-- Replace your eslint-formatting.lua with this:
-- lua/plugins/eslint-formatting.lua

return {
  -- none-ls for eslint_d integration
  {
    'nvimtools/none-ls.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvimtools/none-ls-extras.nvim' -- Required for eslint_d support
    },
    config = function()
      local null_ls = require('null-ls')

      null_ls.setup({
        sources = {
          -- ESLint diagnostics and code actions using eslint_d (from none-ls-extras)
          require("none-ls.diagnostics.eslint_d").with({
            condition = function(utils)
              return utils.root_has_file({
                '.eslintrc.js',
                '.eslintrc.cjs',
                '.eslintrc.yaml',
                '.eslintrc.yml',
                '.eslintrc.json',
                'eslint.config.js',    -- Modern flat config
                'eslint.config.mjs',   -- ES modules flat config
                'eslint.config.cjs',   -- CommonJS flat config
                'package.json'
              })
            end,
          }),
          require("none-ls.code_actions.eslint_d").with({
            condition = function(utils)
              return utils.root_has_file({
                '.eslintrc.js',
                '.eslintrc.cjs',
                '.eslintrc.yaml',
                '.eslintrc.yml',
                '.eslintrc.json',
                'eslint.config.js',    -- Modern flat config
                'eslint.config.mjs',   -- ES modules flat config
                'eslint.config.cjs',   -- CommonJS flat config
                'package.json'
              })
            end,
          }),
          require("none-ls.formatting.eslint_d").with({
            condition = function(utils)
              return utils.root_has_file({
                '.eslintrc.js',
                '.eslintrc.cjs',
                '.eslintrc.yaml',
                '.eslintrc.yml',
                '.eslintrc.json',
                'eslint.config.js',    -- Modern flat config
                'eslint.config.mjs',   -- ES modules flat config
                'eslint.config.cjs',   -- CommonJS flat config
                'package.json'
              })
            end,
          }),
        },
        on_attach = function(client, bufnr)
          -- Format on save for JS/TS/Vue files
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                local ft = vim.bo[bufnr].filetype
                if vim.tbl_contains({
                  'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue'
                }, ft) then
                  vim.lsp.buf.format({
                    filter = function(c)
                      return c.name == "null-ls"
                    end,
                    async = false,
                  })
                end
              end,
            })
          end

          -- Hotkey for manual formatting
          vim.keymap.set('n', '<leader>f', function()
            local ft = vim.bo.filetype
            if vim.tbl_contains({
              'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue'
            }, ft) then
              vim.lsp.buf.format({
                filter = function(c)
                  return c.name == "null-ls"
                end,
                async = true,
              })
              print("Formatted with ESLint")
            else
              -- For other file types, use default formatting
              vim.lsp.buf.format({ async = true })
            end
          end, { buffer = bufnr, desc = 'Format with ESLint' })

          -- ESLint-specific keymaps
          vim.keymap.set('n', '<leader>ef', function()
            vim.lsp.buf.code_action({
              context = {
                only = { "source.fixAll" },
                diagnostics = {},
              },
              apply = true,
            })
            print("ESLint fixes applied")
          end, { buffer = bufnr, desc = 'ESLint: Fix all issues' })

          vim.keymap.set('n', '<leader>eo', function()
            vim.lsp.buf.code_action({
              context = {
                only = { "source.organizeImports" },
                diagnostics = {},
              },
              apply = true,
            })
            print("Imports organized")
          end, { buffer = bufnr, desc = 'ESLint: Organize imports' })

          -- Format selection
          vim.keymap.set('v', '<leader>f', function()
            vim.lsp.buf.format({
              filter = function(c)
                return c.name == "null-ls"
              end,
              async = true,
            })
          end, { buffer = bufnr, desc = 'Format selection with ESLint' })
        end,
      })
    end
  }
}
