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
          -- 'ts_ls',
          "bashls",
          "cssls",
          "emmet_ls",
          "html",
          "jsonls",
          "marksman",
          "pyright",
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
          local servers = { "pyright", "bashls", "html", "cssls", "emmet_ls", "jsonls" }
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
                },
              })
            else
              lspconfig[server].setup({
                capabilities = capabilities,
              })
            end
          end
        end
      end, 100)

      -- LSP key mappings
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }

          -- Navigation
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)

          -- Information
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)

          -- Actions
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

          -- Diagnostics
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1 })
          end, opts)
          vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1 })
          end, opts)
          vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, opts)

          -- Workspace management
          vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
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

      -- LSP keymaps
      vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "LSP Info" })
      vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "LSP Restart" })
      vim.keymap.set("n", "<leader>ma", "<cmd>Mason<cr>", { desc = "Open Mason" })
    end,
  },
}
