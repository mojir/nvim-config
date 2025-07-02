return {
  {
    dir = vim.fn.stdpath("config") .. "/lua",
    name = "lits",
    config = function()
      require("lits").setup()
    end,
  },
}
