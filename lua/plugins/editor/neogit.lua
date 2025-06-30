return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- Your existing diffview
      "nvim-telescope/telescope.nvim", -- Your existing telescope
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Open Neogit" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Git commit" },
      { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Git push" },
      { "<leader>gp", "<cmd>Neogit pull<cr>", desc = "Git pull" },
      { "<leader>gl", "<cmd>Neogit log<cr>", desc = "Git log" },
      { "<leader>gb", "<cmd>Neogit branch<cr>", desc = "Git branch" },
    },
    config = function()
      require("neogit").setup({
        -- Disable built-in keymaps to avoid conflicts
        disable_builtin_notifications = false,
        disable_commit_confirmation = false,
        disable_insert_on_commit = false,

        -- Use your existing diffview for diffs
        integrations = {
          diffview = true,
          telescope = true,
        },

        -- Commit popup options
        commit_popup = {
          kind = "split",
        },

        -- Log popup options
        log_popup = {
          kind = "tab",
        },

        -- Status buffer options
        status = {
          recent_commit_count = 10,
        },

        -- Signs in the gutter
        signs = {
          hunk = { "╎", "┃" },
          item = { "▶", "▼" },
          section = { "▶", "▼" },
        },

        -- Popup window settings
        popup = {
          kind = "split_above",
        },

        -- Auto-refresh when git state changes
        auto_refresh = true,

        -- Use telescope for refs, remotes, etc.
        use_telescope = true,

        -- Customize which buffers to auto-close
        auto_close_console = true,

        -- File watcher for external git changes
        filewatcher = {
          interval = 1000,
          enabled = true,
        },

        -- Graph style
        graph_style = "ascii",
      })

      -- Additional keymaps for when you're inside Neogit
      local group = vim.api.nvim_create_augroup("NeogitCustom", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "Neogit*",
        callback = function(event)
          local opts = { buffer = event.buf, noremap = true, silent = true }

          -- Quick navigation
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, desc = "Close Neogit" })
          vim.keymap.set("n", "<leader>q", "<cmd>Neogit close<cr>", { buffer = event.buf, desc = "Close all Neogit" })

          -- Diff shortcuts
          vim.keymap.set("n", "D", function()
            require("neogit").action("diff", "open")()
          end, { buffer = event.buf, desc = "Open diff" })
        end,
      })
    end,
  },
}
