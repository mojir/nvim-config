-- lua/plugins/diffview.lua
return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("diffview").setup({
        view = {
          merge_tool = {
            layout = "diff3_horizontal", -- 3-way merge: LOCAL | BASE | REMOTE
          },
        },
      })

      -- Essential keymaps
      vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory<cr>", { desc = "File history" })
      vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", { desc = "Current file history" })
      vim.keymap.set("n", "<leader>gr", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh diffview" })
      -- Toggle diffview
      vim.keymap.set("n", "<leader>gd", function()
        local lib = require("diffview.lib")
        local view = lib.get_current_view()
        if view then
          -- Force close any diffview
          vim.cmd("DiffviewClose")
          -- If that didn't work, try tabclose
          if lib.get_current_view() then
            vim.cmd("tabclose")
          end
        else
          -- Open with file panel (same as default DiffviewOpen)
          vim.cmd("DiffviewOpen")
        end
      end, { desc = "Toggle diffview" })
    end,
  },
}
