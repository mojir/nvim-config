return {
  -- DAP for debugging
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'theHamsta/nvim-dap-virtual-text',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')

      -- DAP UI setup
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              "breakpoints",
              "stacks",
              "watches",
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              "repl",
              "console",
            },
            size = 0.25,
            position = "bottom",
          },
        },
        controls = {
          enabled = true,
          element = "repl",
          icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "↻",
            terminate = "□",
          },
        },
        floating = {
          max_height = nil,
          max_width = nil,
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        windows = { indent = 1 },
        render = {
          max_type_length = nil,
          max_value_lines = 100,
        },
      })

      -- Virtual text setup (shows variable values inline)
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        clear_on_continue = false,
        display_callback = function(variable, buf, stackframe, node, options)
          if options.virt_text_pos == 'inline' then
            return ' = ' .. variable.value
          else
            return variable.name .. ' = ' .. variable.value
          end
        end,
        virt_text_pos = vim.fn.has('nvim-0.10') == 1 and 'inline' or 'eol',
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil
      })

      -- Node.js DAP adapter configuration
      dap.adapters.node2 = {
        type = 'executable',
        command = 'node',
        args = {
          vim.fn.stdpath('data') .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js'
        },
      }

      -- Alternative pwa-node adapter (more modern)
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            vim.fn.stdpath('data') .. '/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js',
            "${port}"
          },
        }
      }

      -- Vitest debug configurations
      dap.configurations.typescript = {
        {
          name = "Debug Vitest Tests",
          type = "pwa-node",
          request = "launch",
          program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
          args = {
            "run",
            "--run",
            "--reporter=verbose",
            "${file}",
            "--no-coverage"
          },
          autoAttachChildProcesses = true,
          smartStep = true,
          console = "integratedTerminal",
          cwd = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**" },
          env = {
            NODE_ENV = "test"
          },
        },
        {
          name = "Debug Current Vitest Test",
          type = "pwa-node",
          request = "launch",
          program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
          args = {
            "run",
            "--run",
            "--reporter=verbose",
            "${relativeFile}",
            "--no-coverage"
          },
          autoAttachChildProcesses = true,
          smartStep = true,
          console = "integratedTerminal",
          cwd = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**" },
          env = {
            NODE_ENV = "test"
          },
        },
        {
          name = "Debug Vitest Current Test (name pattern)",
          type = "pwa-node",
          request = "launch",
          program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
          args = function()
            local test_name = vim.fn.input("Test name pattern: ")
            return {
              "run",
              "--run",
              "--reporter=verbose",
              "${file}",
              "--no-coverage",
              "-t", test_name
            }
          end,
          autoAttachChildProcesses = true,
          smartStep = true,
          console = "integratedTerminal",
          cwd = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**" },
          env = {
            NODE_ENV = "test"
          },
        },
      }

      -- Copy configurations for JavaScript
      dap.configurations.javascript = dap.configurations.typescript

      -- DAP event listeners
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- ===== BREAKPOINT KEYMAPS =====

      -- Toggle breakpoint on current line
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle Breakpoint' })

      -- Set conditional breakpoint
      vim.keymap.set('n', '<leader>dB', function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end, { desc = 'Set Conditional Breakpoint' })

      -- Set log point
      vim.keymap.set('n', '<leader>dl', function()
        dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
      end, { desc = 'Set Log Point' })

      -- ===== DEBUG CONTROL KEYMAPS =====

      -- Start/Continue debugging
      vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })

      -- Step controls
      vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'Debug: Step Out' })

      -- Alternative step controls
      vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'Debug: Continue' })
      vim.keymap.set('n', '<leader>do', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<leader>di', dap.step_into, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<leader>dO', dap.step_out, { desc = 'Debug: Step Out' })

      -- Debug UI controls
      vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = 'Debug: Toggle UI' })
      vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'Debug: Open REPL' })
      vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = 'Debug: Terminate' })
      vim.keymap.set('n', '<leader>dR', dap.run_last, { desc = 'Debug: Run Last' })

      -- ===== INSPECTION KEYMAPS =====

      -- Hover to see variable values
      vim.keymap.set({'n', 'v'}, '<leader>dh', function()
        require('dap.ui.widgets').hover()
      end, { desc = 'Debug: Hover' })

      -- Preview variables
      vim.keymap.set({'n', 'v'}, '<leader>dp', function()
        require('dap.ui.widgets').preview()
      end, { desc = 'Debug: Preview' })

      -- Show frames
      vim.keymap.set('n', '<leader>df', function()
        local widgets = require('dap.ui.widgets')
        widgets.centered_float(widgets.frames)
      end, { desc = 'Debug: Frames' })

      -- Show scopes (variables)
      vim.keymap.set('n', '<leader>ds', function()
        local widgets = require('dap.ui.widgets')
        widgets.centered_float(widgets.scopes)
      end, { desc = 'Debug: Scopes' })

      -- ===== VITEST-SPECIFIC DEBUG KEYMAPS =====

      -- Debug nearest test with Neotest
      vim.keymap.set('n', '<leader>td', function()
        require('neotest').run.run({ strategy = 'dap' })
      end, { desc = 'Debug nearest test' })

      -- Debug current file tests with Neotest
      vim.keymap.set('n', '<leader>tD', function()
        require('neotest').run.run({ vim.fn.expand('%'), strategy = 'dap' })
      end, { desc = 'Debug current file tests' })

      -- Manual Vitest debug (fallback)
      vim.keymap.set('n', '<leader>dv', function()
        dap.run(dap.configurations.typescript[1])
      end, { desc = 'Debug Vitest (manual)' })

      -- Clear all breakpoints
      vim.keymap.set('n', '<leader>dC', function()
        dap.clear_breakpoints()
        print("All breakpoints cleared")
      end, { desc = 'Clear all breakpoints' })

      -- List breakpoints
      vim.keymap.set('n', '<leader>dL', function()
        dap.list_breakpoints()
      end, { desc = 'List breakpoints' })
    end,
  },

  -- Mason DAP extension for easy installation
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-dap',
    },
    config = function()
      require('mason-nvim-dap').setup({
        ensure_installed = { 'js-debug-adapter' },
        automatic_installation = true,
        handlers = {
          function(config)
            require('mason-nvim-dap').default_setup(config)
          end,
        },
      })
    end,
  },
}
