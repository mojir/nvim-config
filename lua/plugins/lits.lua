return {
  {
    dir = vim.fn.stdpath("config") .. "/lua",
    name = "lits",
    config = function()
      require("lits").setup()
      vim.keymap.set("n", "<leader>L", ":Lits<cr>", { desc = "Lits" })
      vim.keymap.set("v", "<leader>L", ":Lits<cr>", { desc = "Lits" })
    end,
  },
}
