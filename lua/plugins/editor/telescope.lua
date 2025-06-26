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
      vim.keymap.set("n", "<leader><leader>r", "<cmd>Telescope registers<cr>", { desc = "Show registers" })
      vim.keymap.set("n", "<leader><leader>f", builtin.find_files, { desc = "Telescope find files" })
      vim.keymap.set("n", "<leader><leader>g", function()
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

      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

      require('my_snippets').setup()
    end,
  },
}
