return {
  {
    "rmagatti/auto-session",
    lazy = false,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("auto-session").setup({
        -- Basic session settings
        auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        auto_session_create_enabled = true,

        -- Suppress for certain directories
        auto_session_suppress_dirs = {
          "~/",
          "~/Downloads",
          "~/Documents",
          "~/Desktop",
          "/tmp",
        },

        -- Logging
        log_level = "error",

        -- File types to bypass when saving sessions
        bypass_session_save_file_types = {
          "gitcommit",
          "gitrebase",
          "help",
          "terminal",
        },

        -- Simple hooks - just close nvim-tree
        pre_save_cmds = {
          "NvimTreeClose", -- Simple command instead of function
        },

        post_restore_cmds = {
          function()
            -- Simple nvim-tree restoration
            vim.defer_fn(function()
              if pcall(require, "nvim-tree.api") then
                require("nvim-tree.api").tree.reload()
              end
            end, 100)
          end,
        },

        -- Built-in session-lens configuration
        session_lens = {
          load_on_setup = true,
          theme_conf = {
            border = true,
            layout_config = {
              width = 0.8,
              height = 0.6,
            },
          },
          previewer = false,
          path_display = { "smart" },
          prompt_title = "Sessions",
        },
      })

      -- Keymaps
      vim.keymap.set("n", "<leader>sp", function()
        require("auto-session.session-lens").search_session({})
      end, { desc = "Pick session (Telescope)" })

      vim.keymap.set("n", "<leader>ss", function()
        require("auto-session").SaveSession()
      end, { desc = "Save current session" })

      -- Load telescope extension
      vim.defer_fn(function()
        if pcall(require, "telescope") then
          require("telescope").load_extension("session-lens")
        end
      end, 100)
    end,
  },
}
