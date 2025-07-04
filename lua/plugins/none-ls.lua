-- eslint-formatting

return {
  -- none-ls for eslint_d integration
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvimtools/none-ls-extras.nvim", -- Required for eslint_d support
      "jay-babu/mason-null-ls.nvim",
    },
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        sources = {
          -- ESLint diagnostics and code actions using eslint_d (from none-ls-extras)
          require("none-ls.diagnostics.eslint_d").with({
            condition = function(utils)
              return utils.root_has_file({
                ".eslintrc.js",
                ".eslintrc.cjs",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                ".eslintrc.json",
                "eslint.config.js", -- Modern flat config
                "eslint.config.mjs", -- ES modules flat config
                "eslint.config.cjs", -- CommonJS flat config
                "package.json",
              })
            end,
          }),
          require("none-ls.code_actions.eslint_d").with({
            condition = function(utils)
              return utils.root_has_file({
                ".eslintrc.js",
                ".eslintrc.cjs",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                ".eslintrc.json",
                "eslint.config.js", -- Modern flat config
                "eslint.config.mjs", -- ES modules flat config
                "eslint.config.cjs", -- CommonJS flat config
                "package.json",
              })
            end,
          }),
          require("none-ls.formatting.eslint_d").with({
            condition = function(utils)
              return utils.root_has_file({
                ".eslintrc.js",
                ".eslintrc.cjs",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                ".eslintrc.json",
                "eslint.config.js", -- Modern flat config
                "eslint.config.mjs", -- ES modules flat config
                "eslint.config.cjs", -- CommonJS flat config
                "package.json",
              })
            end,
          }),
        },
        on_attach = function(client, bufnr)
          -- Format on save for JS/TS files
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                local ft = vim.bo[bufnr].filetype
                if
                  vim.tbl_contains({
                    "javascript",
                    "javascriptreact",
                    "typescript",
                    "typescriptreact",
                  }, ft)
                then
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

          -- ESLint-specific keymaps  group under <leader>l (with other LSP actions)
          vim.keymap.set("n", "<leader>lF", function()
            vim.lsp.buf.code_action({
              desc = "ESLint: Fix all issues",
              context = {
                only = { "source.fixAll" },
                diagnostics = {},
              },
              apply = true,
            })
            print("ESLint fixes applied")
          end, { buffer = bufnr, desc = "ESLint: Fix all issues" })

          vim.keymap.set("n", "<leader>lo", function()
            vim.lsp.buf.code_action({
              desc = "ESLint: Organize imports",
              context = {
                only = { "source.organizeImports" },
                diagnostics = {},
              },
              apply = true,
            })
            print("Imports organized")
          end, { buffer = bufnr, desc = "ESLint: Organize imports" })
        end,
      })
    end,
  },
}
