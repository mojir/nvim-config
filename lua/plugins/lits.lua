return {
  {
    dir = vim.fn.stdpath("config") .. "/lua",
    name = "lits",
    cmd = "Lits",  -- Lazy load when :Lits command is used
    keys = {
      { "<leader>L", ":Lits<cr>", desc = "Lits", mode = "n" },
      { "<leader>L", ":Lits<cr>", desc = "Lits", mode = "v" },
    },
    config = function()
      require("lits").setup({
        -- You can override default config here if needed
        -- programs_dir = vim.fn.stdpath("data") .. "/my-lits-programs/",
        -- default_file = "MAIN.lits",
        -- popup = {
        --   border = "single",
        -- },
      })
    end,
  },
}
