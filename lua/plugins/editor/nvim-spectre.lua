-- lua/plugins/nvim-spectre.lua
return {
  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = { "Spectre" },
    keys = {
      { "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', desc = "Toggle Spectre" },
      { 
        "<leader>S", 
        '<esc><cmd>lua require("spectre").open_visual()<CR>', 
        mode = "v", 
        desc = "Search selection" 
      },
      { 
        "<leader>sb", 
        '<cmd>lua require("spectre").open_file_search()<CR>', 
        desc = "Search/replace in current buffer" 
      },
      { 
        "<leader>sb", 
        '<esc><cmd>lua require("spectre").open_file_search()<CR>', 
        mode = "v", 
        desc = "Search selection in current buffer" 
      },
    },
    opts = {},
  },
}
