local ripgrep_config = require("config.ripgrep")

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

      local function get_visual_selection()
        -- Save the current register content
        local saved_reg = vim.fn.getreg('"')
        local saved_regtype = vim.fn.getregtype('"')

        -- Yank the selection
        vim.cmd("normal! y")
        local text = vim.fn.getreg('"')

        -- Restore the register
        vim.fn.setreg('"', saved_reg, saved_regtype)

        return text
      end

      local function escape_for_regex(text, escape)
        -- Split by newlines and take the first line
        local first_line = vim.split(text, "[\r\n]")[1] or ""
        if escape == true then
          return first_line:gsub("[%(%)%[%]%{%}%.%*%+%?%^%$%|\\]", "\\%1")
        end
        return first_line
      end

      local function show_buffers(builtin)
        builtin.buffers({
          attach_mappings = function(prompt_bufnr, map)
            map("i", "<C-d>", function()
              require("telescope.actions").delete_buffer(prompt_bufnr)
            end)
            map("n", "<C-d>", function()
              require("telescope.actions").delete_buffer(prompt_bufnr)
            end)
            return true
          end,
        })
      end

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
              ["<C-s>"] = require("telescope.actions").send_selected_to_qflist
                + require("telescope.actions").open_qflist, -- SELECTED only
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
            find_command = ripgrep_config.find_files_command, -- Use custom ripgrep command for find_files
          },
        },
        extensions = {
          live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            mappings = { -- extend mappings
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
              },
            },
          },
        },
        mouse = false, -- disable mouse support
      })

      telescope.load_extension("live_grep_args")
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<C-f>", builtin.find_files, { desc = "Telescope find files" })
      vim.keymap.set("n", "<C-/>", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy find in buffer" })
      vim.keymap.set("v", "<C-/>", function()
        local search_text = escape_for_regex(get_visual_selection())
        print("search_text", search_text)
        builtin.current_buffer_fuzzy_find({
          default_text = search_text,
        })
      end, { desc = "Fuzzy find in buffer" })
      vim.keymap.set("n", "<C-Space>", function()
        builtin.live_grep({
          additional_args = function()
            return ripgrep_config.default_args
          end,
          prompt_title = "Live grep",
        })
      end, { desc = "Live grep (no args)" })
      vim.keymap.set("n", "<leader><leader>G", function()
        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return ripgrep_config.default_args
          end,
        })
      end, { desc = "Live grep with args" })

      vim.keymap.set("v", "<C-Space>", function()
        local search_text = escape_for_regex(get_visual_selection(), true)
        builtin.live_grep({
          additional_args = function()
            return ripgrep_config.default_args
          end,
          prompt_title = "Live grep",
          default_text = search_text,
        })
      end, { desc = "Live grep" })
      vim.keymap.set("v", "<leader><leader>G", function()
        local search_text = escape_for_regex(get_visual_selection(), true)
        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return ripgrep_config.default_args
          end,
          default_text = search_text,
        })
      end, { desc = "Live grep with args" })
      -- Search for word under cursor
      vim.keymap.set("n", "<leader><leader>w", function()
        local word = escape_for_regex(vim.fn.expand("<cword>"), true)
        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return ripgrep_config.default_args
          end,
          default_text = word,
        })
      end, { desc = "Search word under cursor" })

      -- Search for WORD under cursor
      vim.keymap.set("n", "<leader><leader>W", function()
        local word = escape_for_regex(vim.fn.expand("<cWORD>"), true)
        require("telescope").extensions.live_grep_args.live_grep_args({
          additional_args = function()
            return ripgrep_config.default_args
          end,
          default_text = word,
        })
      end, { desc = "Search WORD under cursor" })

      vim.keymap.set("n", "<leader><leader>m", "<cmd>Telescope marks<cr>", { desc = "Show marks" })
      vim.keymap.set("n", "<leader><leader>re", "<cmd>Telescope registers<cr>", { desc = "Show registers" })

      vim.keymap.set("n", "<leader><leader>b", function()
        show_buffers(builtin)
      end, { desc = "Telescope buffers" })
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
      vim.keymap.set("n", "<leader><leader>S", builtin.spell_suggest, { desc = "Spelling suggestions" })

      -- History and resume
      vim.keymap.set("n", "<leader><leader>p", builtin.pickers, { desc = "Previous pickers" })
      vim.keymap.set("n", "<leader><leader>re", builtin.resume, { desc = "Resume last picker" })
      vim.keymap.set("n", "<leader><leader>ch", builtin.command_history, { desc = "Command history" })
      vim.keymap.set("n", "<leader><leader>H", builtin.search_history, { desc = "Search history" })

      -- Utility
      vim.keymap.set("n", "<leader><leader>cs", builtin.colorscheme, { desc = "Colorschemes" })
      require("my_snippets").setup()
    end,
  },
}
