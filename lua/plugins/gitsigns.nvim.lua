return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 1000,
          ignore_whitespace = false,
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true })

          -- Actions
          map("n", "<leader>gsa", gs.stage_hunk)
          map("n", "<leader>gsA", gs.stage_buffer)
          map("n", "<leader>gsr", gs.undo_stage_hunk)
          map("n", "<leader>gsx", gs.reset_hunk)
          map("n", "<leader>gsX", gs.reset_buffer)
          map("n", "<leader>gsp", gs.preview_hunk)
          map("n", "<leader>gsb", gs.toggle_current_line_blame)
          map("n", "<leader>gst", gs.toggle_deleted)
          map("n", "<leader>gsg", gs.refresh)
        end,
      })

      vim.keymap.set("n", "<leader>gR", function()
        local current_file = vim.fn.expand("%:p")
        if current_file == "" then
          print("No file to unstage")
          return
        end

        -- Use git to unstage the file
        vim.fn.system("git reset HEAD -- " .. vim.fn.shellescape(current_file))
        require("gitsigns").refresh()
        print("Unstaged: " .. vim.fn.fnamemodify(current_file, ":t"))
      end, { desc = "Unstage entire buffer" })
    end,
  },
}
