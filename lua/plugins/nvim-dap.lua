return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }

      dap.configurations["typescript"] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
        },
        -- {
        --   type = "pwa-node",
        --   request = "attach",
        --   name = "Attach to process ID",
        --   processId = require("dap.utils").pick_process,
        --   cwd = "${workspaceFolder}",
        -- },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Vitest Tests",
          cwd = "${workspaceFolder}",
          program = "${workspaceFolder}/node_modules/.bin/vitest",
          args = { "--run", "${file}" },
          autoAttachChildProcesses = true,
          smartStep = true,
          console = "integratedTerminal",
          skipFiles = { "<node_internals>/**" },
        },
      }
      -- Setup DAP UI
      dapui.setup()

      -- Auto open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Add this to your nvim-dap.lua config function
      local breakpoints_file = vim.fn.stdpath("data") .. "/dap-breakpoints.json"

      -- Function to save all breakpoints immediately
      local function save_breakpoints()
        local breakpoints = {}
        local bps = require("dap.breakpoints").get()

        for bufnr, buf_bps in pairs(bps) do
          local file_path = vim.api.nvim_buf_get_name(bufnr)
          if file_path ~= "" then
            breakpoints[file_path] = buf_bps
          end
        end

        local file = io.open(breakpoints_file, "w")
        if file then
          file:write(vim.fn.json_encode(breakpoints))
          file:close()
        end
      end

      -- Hook into DAP events to auto-save breakpoints

      -- Also save when manually called (fallback)
      local group = vim.api.nvim_create_augroup("DapBreakpointPersist", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        callback = function()
          vim.defer_fn(save_breakpoints, 100)
        end,
      })

      -- Load breakpoints when opening files
      vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function()
          local file = io.open(breakpoints_file, "r")
          if file then
            local content = file:read("*a")
            file:close()

            local ok, breakpoints = pcall(vim.fn.json_decode, content)
            if ok and breakpoints then
              local current_file = vim.api.nvim_buf_get_name(0)
              local file_bps = breakpoints[current_file]

              if file_bps then
                for _, bp in ipairs(file_bps) do
                  -- Fixed: set_breakpoint takes (condition, hit_condition, log_message)
                  -- We want to set it on the specific line, so we need to position cursor first
                  vim.api.nvim_win_set_cursor(0, { bp.line, 0 })
                  dap.set_breakpoint()
                end
              end
            end
          end
        end,
      })

      -- Basic keymaps
      vim.keymap.set("n", "<leader>db", function()
        dap.toggle_breakpoint()
        vim.defer_fn(save_breakpoints, 50)
      end, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
      vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
      vim.keymap.set("n", "<leader>dB", function()
        require("dap").clear_breakpoints()
        vim.defer_fn(save_breakpoints, 50)
        print("All breakpoints cleared")
      end, { desc = "Clear all breakpoints" })
      vim.keymap.set("n", "<leader>dC", function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Conditional breakpoint" })

      vim.keymap.set("n", "<leader>dl", function()
        local bps = require("dap.breakpoints").get()
        if vim.tbl_isempty(bps) then
          print("No breakpoints set")
          return
        end

        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local previewers = require("telescope.previewers")

        local results = {}
        for bufnr, buf_bps in pairs(bps) do
          local file_name = vim.api.nvim_buf_get_name(bufnr)

          if file_name ~= "" then
            for _, bp in ipairs(buf_bps) do
              table.insert(results, {
                display = string.format("%s:%d", vim.fn.fnamemodify(file_name, ":t"), bp.line),
                filename = file_name,
                lnum = bp.line,
                col = 1,
              })
            end
          end
        end

        -- Also check persisted breakpoints file
        local breakpoints_file = vim.fn.stdpath("data") .. "/dap-breakpoints.json"
        local file = io.open(breakpoints_file, "r")
        if file then
          local content = file:read("*a")
          file:close()

          local ok, saved_breakpoints = pcall(vim.fn.json_decode, content)
          if ok and saved_breakpoints then
            for file_path, file_bps in pairs(saved_breakpoints) do
              if vim.fn.filereadable(file_path) == 1 then
                local already_added = false
                for _, result in ipairs(results) do
                  if result.filename == file_path then
                    already_added = true
                    break
                  end
                end

                if not already_added then
                  for _, bp in ipairs(file_bps) do
                    table.insert(results, {
                      display = string.format("%s:%d", vim.fn.fnamemodify(file_path, ":t"), bp.line),
                      filename = file_path,
                      lnum = bp.line,
                      col = 1,
                    })
                  end
                end
              end
            end
          end
        end

        if vim.tbl_isempty(results) then
          print("No breakpoints found")
          return
        end

        pickers
          .new({}, {
            prompt_title = "DAP Breakpoints",
            finder = finders.new_table({
              results = results,
              entry_maker = function(entry)
                return {
                  value = entry,
                  display = entry.display,
                  ordinal = entry.display,
                  filename = entry.filename,
                  lnum = entry.lnum,
                  col = entry.col,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            previewer = conf.grep_previewer({}),
          })
          :find()
      end, { desc = "List breakpoints" })
    end,
  },
}
