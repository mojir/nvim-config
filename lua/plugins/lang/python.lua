return {
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp", -- Use the new branch
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap-python",
      { "nvim-telescope/telescope.nvim", branch = "0.1.x", optional = true },
    },
    lazy = false,
    config = function()
      require("venv-selector").setup({})
      vim.keymap.set("n", "<leader>vs", "<cmd>VenvSelect<cr>", { desc = "Select Python venv" })
    end,
  },
}
