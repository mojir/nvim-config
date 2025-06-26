return {
  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
        config = function()
          require("telescope").load_extension("live_grep_args")
        end,
      },
    },
    config = function()
      local telescope = require("telescope")
      local lga_actions = require("telescope-live-grep-args.actions")

      telescope.setup({
        defaults = {
          file_ignore_patterns = {
            "%.git/",
            "node_modules/",
            "%.DS_Store",
          },
          hidden = true,
          defaults = {
            history = {
              path = vim.fn.stdpath("data") .. "/telescope_history",
              limit = 100,
            },
          },
          mappings = {
            i = {
              ["<C-p>"] = require("telescope.actions").cycle_history_prev,
              ["<C-n>"] = require("telescope.actions").cycle_history_next,
            },
          },
        },
        pickers = {
          live_grep = {
            additional_args = function()
              return { "--hidden" }
            end,
          },
          find_files = {
            hidden = true,
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--glob", "!.git/*",
              "--glob", "!node_modules/*"
            },
          },
        },
        extensions = {
          live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            -- define mappings, e.g.
            mappings = { -- extend mappings
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
              },
            },
            -- ... also accepts theme settings, for example:
            -- theme = "dropdown", -- use dropdown theme
            -- theme = { }, -- use own theme spec
            -- layout_config = { mirror=true }, -- mirror preview pane
          },
        },
        mouse = false, -- disable mouse support
      })

      telescope.load_extension("live_grep_args")
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader><leader>m", "<cmd>Telescope marks<cr>", { desc = "Show registers" })
      vim.keymap.set("n", "<leader><leader>re", "<cmd>Telescope registers<cr>", { desc = "Show registers" })
      vim.keymap.set("n", "<leader><leader>f", builtin.find_files, { desc = "Telescope find files" })
      vim.keymap.set("n", "<leader><leader>?", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy find in buffer" })
      vim.keymap.set("n", "<leader><leader>/", function()
        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return { "--hidden" }
          end,
        })
      end, { desc = "Live grep with args (including hidden)" })

      vim.keymap.set("v", "<leader><leader>g", function()
        -- Simply yank the selection and get it from the default register
        vim.cmd("normal! y")
        local search_text = vim.fn.getreg('"')

        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return { "--hidden" }
          end,
          default_text = search_text,
        })
      end, { desc = "Live grep with args (including hidden)" })
      -- Search for word under cursor
      vim.keymap.set("n", "<leader><leader>w", function()
        local word = vim.fn.expand("<cword>")
        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return { "--hidden" }
          end,
          default_text = word,
        })
      end, { desc = "Search word under cursor" })

      -- Search for WORD under cursor
      vim.keymap.set("n", "<leader><leader>W", function()
        local word = vim.fn.expand("<cWORD>")
        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return { "--hidden" }
            end,
          default_text = word,
        })
      end, { desc = "Search WORD under cursor" })

      vim.keymap.set("n", "<leader><leader>b", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader><leader>co", builtin.commands, { desc = "Telescope commands" })
      vim.keymap.set("n", "<leader><leader>h", builtin.help_tags, { desc = "Telescope help tags" })

      -- Core navigation
      vim.keymap.set("n", "<leader><leader>o", builtin.oldfiles, { desc = "Recent files" })
      vim.keymap.set("n", "<leader><leader>j", builtin.jumplist, { desc = "Jump list" })
      vim.keymap.set("n", "<leader><leader>q", builtin.quickfix, { desc = "Quickfix list" })
      vim.keymap.set("n", "<leader><leader>ll", builtin.loclist, { desc = "Location list" })

      -- LSP pickers
      vim.keymap.set("n", "<leader><leader>lr", builtin.lsp_references, { desc = "LSP references" })
      vim.keymap.set("n", "<leader><leader>ld", builtin.lsp_definitions, { desc = "LSP definitions" })
      vim.keymap.set("n", "<leader><leader>li", builtin.lsp_implementations, { desc = "LSP implementations" })
      vim.keymap.set("n", "<leader><leader>lt", builtin.lsp_type_definitions, { desc = "LSP type definitions" })
      vim.keymap.set("n", "<leader><leader>lS", builtin.lsp_document_symbols, { desc = "Document symbols" })
      vim.keymap.set("n", "<leader><leader>ls", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })

      -- All buffers diagnostics
      vim.keymap.set("n", "<leader><leader>d", builtin.diagnostics, { desc = "Diagnostics (all buffers)" })
      -- Current buffer only diagnostics
      vim.keymap.set("n", "<leader><leader>D", function()
        builtin.diagnostics({ bufnr = 0 })
      end, { desc = "Diagnostics (current buffer)" })

      -- Git pickers
      vim.keymap.set("n", "<leader><leader>gc", builtin.git_commits, { desc = "Git commits" })
      vim.keymap.set("n", "<leader><leader>gC", builtin.git_bcommits, { desc = "Git commits" })
      vim.keymap.set("n", "<leader><leader>gb", builtin.git_branches, { desc = "Git branches" })
      vim.keymap.set("n", "<leader><leader>gs", builtin.git_status, { desc = "Git status" })
      vim.keymap.set("n", "<leader><leader>gt", builtin.git_stash, { desc = "Git stash" })

      -- Buffer/file operations
      vim.keymap.set("n", "<leader><leader>t", builtin.treesitter, { desc = "Treesitter symbols" })

      -- Vim introspection
      vim.keymap.set("n", "<leader><leader>k", builtin.keymaps, { desc = "Keymaps" })
      vim.keymap.set("n", "<leader><leader>a", builtin.autocommands, { desc = "Autocommands" })
      vim.keymap.set("n", "<leader><leader>v", builtin.vim_options, { desc = "Vim options" })
      vim.keymap.set("n", "<leader><leader>sc", builtin.spell_suggest, { desc = "Spelling suggestions" })

      -- History and resume
      vim.keymap.set("n", "<leader><leader>p", builtin.pickers, { desc = "Previous pickers" })
      vim.keymap.set("n", "<leader><leader>re", builtin.resume, { desc = "Resume last picker" })
      vim.keymap.set("n", "<leader><leader>ch", builtin.command_history, { desc = "Command history" })
      vim.keymap.set("n", "<leader><leader>sh", builtin.search_history, { desc = "Search history" })

      -- Utility
      vim.keymap.set("n", "<leader><leader>cs", builtin.colorscheme, { desc = "Colorschemes" })
      require('my_snippets').setup()
    end,
  },
}
