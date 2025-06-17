-- Basic yanky.nvim configuration with lazy loading
return {
  {
    "gbprod/yanky.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
      { "<leader>fy", "<cmd>Telescope yank_history<cr>", desc = "Yank history" },
    },
    config = function()
      require("yanky").setup({
        ring = {
          history_length = 50,
          storage = "shada",
          sync_with_numbered_registers = true,
        },
        system_clipboard = {
          sync_with_ring = true,
        },
        highlight = {
          on_put = true,
          on_yank = true,
          timer = 500,
        },
        preserve_cursor_position = {
          enabled = true,
        },
      })

      -- Load telescope extension
      require("telescope").load_extension("yank_history")
    end,
  },
}
