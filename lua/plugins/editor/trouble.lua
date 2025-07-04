return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>ll", "<cmd>Trouble diagnostics toggle<cr>", desc = "List Diagnostics (Trouble)" },
      { "<leader>lL", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "List Buffer Diagnostics (Trouble)" },
      -- { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      -- { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)" },
      -- { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      -- { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
    opts = {},
  },
}
