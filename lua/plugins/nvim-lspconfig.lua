return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "b0o/schemastore.nvim",
    },
    config = function()
      pcall(vim.keymap.del, "n", "grr")
      pcall(vim.keymap.del, "n", "grn")
      pcall(vim.keymap.del, "n", "gri")
      pcall(vim.keymap.del, "n", "gra")

      -- Mason setup
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",
          "bashls",
          "cssls",
          "emmet_ls",
          "html",
          "jsonls",
          "marksman",
          "pyright",
          "vue_ls",
        },
        automatic_enable = false,
      })

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local server_configs = {
        jsonls = {
          capabilities = capabilities,
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        emmet_ls = {
          capabilities = capabilities,
          filetypes = {
            "html",
            "css",
            "scss",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
          },
        },
        -- In your server_configs table, add:
        volar = {
          capabilities = capabilities,
          filetypes = { "vue" },
          init_options = {
            vue = {
              hybridMode = false,
            },
          },
        },
      }

      -- Lua LSP setup
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = {
              globals = { "vim" },
              disable = { "trailing-space" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
            format = { enable = true },
          },
        },
      })

      -- Setup other servers
      vim.defer_fn(function()
        local mason_lspconfig = require("mason-lspconfig")

        if mason_lspconfig.setup_handlers then
          mason_lspconfig.setup_handlers({
            function(server_name)
              if server_name == "lua_ls" then
                return
              end
              local config = server_configs[server_name] or { capabilities = capabilities }
              lspconfig[server_name].setup(config)
            end,
          })
        else
          -- local servers = { 'pyright', 'bashls', 'html', 'cssls', 'emmet_ls', 'ts_ls' }
          local servers = { "pyright", "bashls", "html", "cssls", "emmet_ls", "jsonls", "volar", "ts_ls" }
          for _, server in ipairs(servers) do
            if server == "emmet_ls" then
              lspconfig[server].setup({
                capabilities = capabilities,
                filetypes = {
                  "html",
                  "css",
                  "scss",
                  "javascript",
                  "javascriptreact",
                  "typescript",
                  "typescriptreact",
                  "vue",
                },
              })
            else
              lspconfig[server].setup({
                capabilities = capabilities,
              })
            end
          end
        end

        -- ts_ls specifically for symbols only
        lspconfig.ts_ls.setup({
          capabilities = capabilities,
          -- Disable everything except symbols to avoid conflicts with typescript-tools
          handlers = {
            -- Disable these to let typescript-tools handle them
            ["textDocument/hover"] = function()
              return nil
            end,
            ["textDocument/completion"] = function()
              return nil
            end,
            ["textDocument/signatureHelp"] = function()
              return nil
            end,
            ["textDocument/publishDiagnostics"] = function()
              return nil
            end,
            ["textDocument/codeAction"] = function()
              return nil
            end,
            ["textDocument/rename"] = function()
              return nil
            end,
            ["textDocument/definition"] = function()
              return nil
            end,
            ["textDocument/references"] = function()
              return nil
            end,
          },
          init_options = {
            preferences = {
              disableSuggestions = true,
            },
          },
          settings = {
            typescript = {
              preferences = {
                disableSuggestions = true,
              },
            },
          },
        })
      end, 100)

      -- LSP key mappings
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }

          local function lsp_map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
          end

          -- Navigation
          lsp_map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          lsp_map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          lsp_map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
          lsp_map("n", "go", vim.lsp.buf.type_definition, "Go to type definition")
          lsp_map("n", "gr", vim.lsp.buf.references, "Go to references")
          lsp_map("n", "gs", vim.lsp.buf.signature_help, "Show signature help")

          -- Information
          lsp_map("n", "K", function()
            vim.lsp.buf.hover({
              border = "rounded",
              title = " Info ",
              title_pos = "center",
            })
          end, "Show hover information")
          lsp_map("n", "<C-k>", vim.lsp.buf.signature_help, "Show signature help")

          -- Actions
          lsp_map("n", "<leader>lr", vim.lsp.buf.rename, "LSP Rename")
          lsp_map("n", "<leader>lu", "<cmd>TSToolsRemoveUnused<cr>", "Remove unused imports")
          lsp_map("n", "<leader>li", "<cmd>TSToolsAddMissingImports<cr>", "Add missing imports")
          lsp_map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP Code Action")
          lsp_map("n", "<leader>le", vim.diagnostic.open_float, "LSP Error details")
          lsp_map("n", "<leader>lI", "<cmd>LspInfo<cr>", "LSP Info")
          lsp_map("n", "<leader>lR", "<cmd>LspRestart<cr>", "LSP Restart")

          -- Diagnostics
          lsp_map("n", "[d", function()
            vim.diagnostic.jump({ count = -1 })
          end, "Previous diagnostic")
          lsp_map("n", "]d", function()
            vim.diagnostic.jump({ count = 1 })
          end, "Next diagnostic")

          -- Workspace management
          -- vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
          -- vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
          -- vim.keymap.set("n", "<leader>wl", function()
          --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          -- end, opts)
        end,
      })

      -- Create custom LSP commands
      vim.api.nvim_create_user_command("LspInfo", function()
        local clients = vim.lsp.get_clients()
        if #clients == 0 then
          print("No active LSP clients")
          return
        end

        for _, client in ipairs(clients) do
          print(string.format("%s (id: %d)", client.name, client.id))
        end
      end, { desc = "Show LSP client info" })

      vim.api.nvim_create_user_command("LspRestart", function()
        local clients = vim.lsp.get_clients()
        for _, client in ipairs(clients) do
          vim.lsp.stop_client(client.id)
        end
        vim.defer_fn(function()
          vim.cmd("edit")
        end, 100)
      end, { desc = "Restart LSP clients" })
    end,
  },
}
