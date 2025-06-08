-- Basic flash.nvim configuration
-- Add this to your plugins/ directory (e.g., lua/plugins/flash.lua)

return {
  {
    'folke/flash.nvim',
    event = "VeryLazy",
    config = function()
      require('flash').setup({
        -- Basic flash settings
        labels = "asdfghjklqwertyuiopzxcvbnm",
        search = {
          multi_window = true,
          forward = true,
          wrap = true,
          mode = "exact", -- exact|search|fuzzy
        },
        jump = {
          jumplist = true,
          pos = "start", -- start|end|range
          history = false,
          register = false,
        },
        label = {
          uppercase = true,
          exclude = "",
          current = true,
          after = true,
          before = false,
          style = "overlay", -- overlay|inline|eol
          reuse = "lowercase",
        },
        highlight = {
          backdrop = true,
          matches = true,
          priority = 5000,
          groups = {
            match = "FlashMatch",
            current = "FlashCurrent",
            backdrop = "FlashBackdrop",
            label = "FlashLabel",
          },
        },
        modes = {
          search = {
            enabled = true,
          },
          char = {
            enabled = true,
            jump_labels = false,
          },
        },
      })
    end,
    keys = {
      -- Main flash jump - replaces traditional search
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      
      -- Treesitter-based jumping (smart code navigation)
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      
      -- Remote flash (for operators like d, c, y)
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      
      -- Treesitter search (visual/operator pending)
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      
      -- Toggle flash in command mode search
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
}
