local ripgrep_config = require("config.ripgrep")

return {
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")

          -- Apply all default mappings first
          api.config.mappings.default_on_attach(bufnr)

          -- Override <C-]> to show a helpful message instead of the tag error
          vim.keymap.set("n", "<C-]>", function()
            print("This action is disabled in nvim-tree")
          end, { buffer = bufnr, desc = "Disabled", silent = true })

          -- You can also override other keys you don't want
          vim.keymap.set("n", "cd", function()
            print("Directory change disabled")
          end, { buffer = bufnr, desc = "Disabled", silent = true })

          vim.keymap.set("n", "C", function()
            print("Root change disabled")
          end, { buffer = bufnr, desc = "Disabled", silent = true })
          -- In nvim-tree on_attach function - this takes precedence in nvim-tree buffers
          vim.keymap.set("n", "<C-/>", function()
            local node = api.tree.get_node_under_cursor()
            if node then
              local path = node.absolute_path
              if node.type == "file" then
                path = vim.fn.fnamemodify(path, ":h")
              end

              require("telescope.builtin").live_grep({
                cwd = path,

                additional_args = function()
                  return ripgrep_config.default_args
                end,
                prompt_title = "Live grep in " .. vim.fn.fnamemodify(path, ":t"),
              })
            end
          end, { buffer = bufnr, desc = "Live grep in selected folder" })
          vim.keymap.set("n", "<leader><leader>/", function()
            local node = api.tree.get_node_under_cursor()

            if node then
              local path = node.absolute_path
              if node.type == "file" then
                path = vim.fn.fnamemodify(path, ":h")
              end

              require("telescope").extensions.live_grep_args.live_grep_args({
                cwd = path,
                additional_args = function()
                  return ripgrep_config.default_args
                end,
                prompt_title = "live grep (args) in " .. vim.fn.fnamemodify(path, ":t"),
              })
            end
          end, { buffer = bufnr, desc = "live grep in selected folder" })
        end,

        view = {
          width = {
            min = 30,
            max = 100,
          },
          side = "left",
        },

        filters = {
          dotfiles = false,
          git_clean = false,
          no_buffer = false,
          custom = {},
        },
        git = {
          enable = true,
          ignore = false,
          show_on_dirs = true,
          show_on_open_dirs = true,
          timeout = 400,
        },
        renderer = {
          highlight_git = true,
          icons = {
            show = {
              git = true,
            },
          },
        },

        sync_root_with_cwd = false, -- Don't change nvim-tree root when cwd changes
        respect_buf_cwd = false, -- Don't change root based on buffer's directory
        actions = {
          change_dir = {
            enable = false, -- Disable 'cd' action in nvim-tree
            global = false, -- Don't change global working directory
            restrict_above_cwd = true,
          },
        },
        filesystem_watchers = {
          enable = true,
          debounce_delay = 50,
          ignore_dirs = {
            "node_modules",
            ".git",
          },
        },
      })

      vim.api.nvim_set_keymap("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<C-M-n>", function()
        local api = require("nvim-tree.api")
        if api.tree.is_visible() then
          api.tree.find_file({ focus = true })
        else
          api.tree.open({ find_file = true })
        end
      end, {
        desc = "Toggle tree and find current file",
      })
    end,
  },
}
