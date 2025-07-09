return {
  {
    dir = vim.fn.stdpath("config"),
    name = "simple-session",
    config = function()
      require("session").setup()
    end,
  },
}
