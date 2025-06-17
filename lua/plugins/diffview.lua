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
      vim.keymap.set("n", "<leader>dvo", "<cmd>DiffviewOpen<cr>", { desc = "Open diffview" })
      vim.keymap.set("n", "<leader>dvc", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" })
      vim.keymap.set("n", "<leader>dvh", "<cmd>DiffviewFileHistory<cr>", { desc = "File history" })
      vim.keymap.set("n", "<leader>dvH", "<cmd>DiffviewFileHistory %<cr>", { desc = "Current file history" })
      vim.keymap.set("n", "<leader>dvr", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh diffview" })
    end,
  },
}
