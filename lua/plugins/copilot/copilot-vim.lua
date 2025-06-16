return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
    config = function()
      -- Disable default tab mapping to avoid conflicts with nvim-cmp
      vim.g.copilot_no_tab_map = true

      -- Set up custom keymaps
      vim.keymap.set("i", "<C-l>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        desc = "Accept Copilot suggestion",
      })

      -- Navigation through suggestions (Mac-friendly alternatives)
      vim.keymap.set("i", "<C-j>", "<Plug>(copilot-next)", { desc = "Next Copilot suggestion" })
      vim.keymap.set("i", "<C-k>", "<Plug>(copilot-previous)", { desc = "Previous Copilot suggestion" })

      -- Dismiss suggestion
      vim.keymap.set("i", "<C-\\>", "<Plug>(copilot-dismiss)", { desc = "Dismiss Copilot suggestion" })

      -- Configure Copilot settings
      vim.g.copilot_filetypes = {
        ["*"] = false,
        python = true,
        javascript = true,
        typescript = true,
        javascriptreact = true,
        typescriptreact = true,
        lua = true,
        html = true,
        css = true,
        scss = true,
        json = true,
        yaml = true,
        markdown = true,
        bash = true,
        sh = true,
        vim = true,
      }
    end,
  },
}
