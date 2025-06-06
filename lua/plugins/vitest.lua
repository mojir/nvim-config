-- Clean vitest.lua configuration
return {
  {
    'marilari88/neotest-vitest',
    dependencies = {
      'nvim-neotest/neotest',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-vitest')({
            -- Custom test file detection
            is_test_file = function(file_path)
              local test_patterns = {
                "%.test%.ts$",
                "%.test%.js$",
                "%.test%.tsx$",
                "%.test%.jsx$",
                "%.spec%.ts$",
                "%.spec%.js$",
                "%.spec%.tsx$",
                "%.spec%.jsx$",
                "__tests__/.*%.ts$",
                "__tests__/.*%.js$",
                "__tests__/.*%.tsx$",
                "__tests__/.*%.jsx$",
              }

              for _, pattern in ipairs(test_patterns) do
                if file_path:match(pattern) then
                  return true
                end
              end
              return false
            end,

            -- Directory filtering
            filter_dir = function(name, rel_path, root)
              local ignore_dirs = {
                "node_modules",
                ".git",
                "dist",
                "build",
                ".next",
                "coverage",
                ".nyc_output"
              }

              for _, ignore in ipairs(ignore_dirs) do
                if name == ignore then
                  return false
                end
              end
              return true
            end,

            -- Smart vitest command detection
            vitestCommand = function()
              local commands = {
                "npx vitest",
                "yarn vitest",
                "pnpm vitest",
                "npm run test",
                "yarn test",
                "pnpm test"
              }

              for _, cmd in ipairs(commands) do
                local handle = io.popen(cmd:gsub("vitest", "vitest --version") .. " 2>/dev/null")
                if handle then
                  local result = handle:read("*a")
                  handle:close()
                  if result and result ~= "" then
                    return cmd
                  end
                end
              end

              return "npx vitest"
            end,

            -- Config file detection
            vitestConfigFile = function()
              local config_files = {
                "vitest.config.ts",
                "vitest.config.js",
                "vitest.config.mjs",
                "vite.config.ts",
                "vite.config.js",
                "vite.config.mjs"
              }

              for _, config in ipairs(config_files) do
                if vim.fn.filereadable(config) == 1 then
                  return config
                end
              end

              return "vitest.config.ts"
            end,

            cwd = function()
              local root_patterns = { "package.json", ".git", "vitest.config.*", "vite.config.*" }
              local root = vim.fs.find(root_patterns, { upward = true })[1]
              if root then
                return vim.fn.fnamemodify(root, ":h")
              end
              return vim.fn.getcwd()
            end,

            env = {
              NODE_ENV = "test",
            },
            dap = {
              justMyCode = false,
              console = "integratedTerminal",
            },
          }),
        },

        discovery = {
          enabled = true,
          concurrent = 1,
        },

        running = {
          concurrent = true,
        },

        summary = {
          enabled = true,
          animated = true,
          follow = true,
          expand_errors = true,
          open = "botright vsplit | vertical resize 50",
        },

        output = {
          enabled = true,
          open_on_run = "short",
        },

        quickfix = {
          enabled = true,
          open = false,
        },

        status = {
          enabled = true,
          virtual_text = true,
          signs = true,
        },

        icons = {
          child_indent = "│",
          child_prefix = "├",
          collapsed = "─",
          expanded = "╮",
          failed = "✖",
          final_child_indent = " ",
          final_child_prefix = "╰",
          non_collapsible = "─",
          passed = "✓",
          running = "●",
          running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
          skipped = "○",
          unknown = "?",
        },

        floating = {
          border = "rounded",
          max_height = 0.8,
          max_width = 0.8,
          options = {},
        },
      })

      local neotest = require('neotest')

      -- Test running
      vim.keymap.set('n', '<leader>tr', function()
        neotest.run.run()
      end, { desc = 'Run nearest test' })

      vim.keymap.set('n', '<leader>tf', function()
        neotest.run.run(vim.fn.expand('%'))
      end, { desc = 'Run current file tests' })

      vim.keymap.set('n', '<leader>ta', function()
        neotest.run.run(vim.fn.getcwd())
      end, { desc = 'Run all tests' })

      vim.keymap.set('n', '<leader>tl', function()
        neotest.run.run_last()
      end, { desc = 'Run last test' })

      -- Test UI
      vim.keymap.set('n', '<leader>ts', function()
        neotest.summary.toggle()
      end, { desc = 'Toggle test summary' })

      vim.keymap.set('n', '<leader>to', function()
        neotest.output.open({ enter = true, auto_close = true })
      end, { desc = 'Show test output' })

      vim.keymap.set('n', '<leader>tO', function()
        neotest.output_panel.toggle()
      end, { desc = 'Toggle test output panel' })

      -- Test navigation
      vim.keymap.set('n', ']t', function()
        neotest.jump.next({ status = 'failed' })
      end, { desc = 'Jump to next failed test' })

      vim.keymap.set('n', '[t', function()
        neotest.jump.prev({ status = 'failed' })
      end, { desc = 'Jump to previous failed test' })

      -- Test control
      vim.keymap.set('n', '<leader>tS', function()
        neotest.run.stop()
      end, { desc = 'Stop test run' })

      vim.keymap.set('n', '<leader>tw', function()
        neotest.watch.toggle()
      end, { desc = 'Toggle test watch mode' })

      vim.keymap.set('n', '<leader>tW', function()
        neotest.watch.toggle(vim.fn.expand('%'))
      end, { desc = 'Toggle watch for current file' })

      vim.keymap.set('n', '<leader>tc', function()
        neotest.state.clear()
      end, { desc = 'Clear test results' })

      vim.keymap.set('n', '<leader>td', function()
        require('neotest').run.run({ strategy = 'dap' })
      end, { desc = 'Debug nearest test' })

      vim.keymap.set('n', '<leader>tD', function()
        require('neotest').run.run({ vim.fn.expand('%'), strategy = 'dap' })
      end, { desc = 'Debug current file tests' })

      -- Keep one useful command for future troubleshooting
      vim.keymap.set('n', '<leader>tR', function()
        neotest.state.refresh_adapters()
        print("Refreshed test adapters")
      end, { desc = 'Refresh test discovery' })
    end,
  },
}
