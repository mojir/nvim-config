return {
  "nvim-telescope/telescope-symbols.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  cmd = { "Telescope symbols" },
  keys = {
    { "<leader><leader>ss", "<cmd>Telescope symbols<cr>", desc = "All symbols" },
    {
      "<leader><leader>se",
      function()
        require("telescope.builtin").symbols({ sources = { "emoji" } })
      end,
      desc = "Emoji symbols",
    },
    {
      "<leader><leader>sm",
      function()
        require("telescope.builtin").symbols({ sources = { "math" } })
      end,
      desc = "Math symbols",
    },
    {
      "<leader><leader>sg",
      function()
        require("telescope.builtin").symbols({ sources = { "gitmoji" } })
      end,
      desc = "Git emoji",
    },
    {
      "<leader><leader>sk",
      function()
        require("telescope.builtin").symbols({ sources = { "kaomoji" } })
      end,
      desc = "Kaomoji",
    },
    {
      "<leader><leader>sa",
      function()
        require("telescope.builtin").symbols({ sources = { "arrows" } })
      end,
      desc = "Arrow symbols",
    },
  },
}
