
return {
  {
    "petertriho/nvim-scrollbar",
    config = function()
      require("scrollbar").setup({
        excluded_filetypes = {
          "prompt",
          "TelescopePrompt", 
          "noice",
          "notify",
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true,
        },
        handle = {
          color = "#3a3d55",
          text = " ",
          hide_if_all_visible = false,
        },
      })
    end,
  },
}
