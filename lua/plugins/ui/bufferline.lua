return {
  -- Buffer line
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          numbers = "ordinal",
          close_command = "bdelete! %d",
          right_mouse_command = "bdelete! %d",
          left_mouse_command = "buffer %d",
          indicator = {
            icon = "▎",
            style = "icon",
          },
          buffer_close_icon = "󰅖",
          modified_icon = "●",
          close_icon = "",
          left_trunc_marker = "",
          right_trunc_marker = "",
          diagnostics = "nvim_lsp",
          separator_style = "slant",
          hover = {
            enabled = true,
            delay = 200,
            reveal = { "close" },
          },
          custom_filter = function(buf_number, _)
            local buf_name = vim.api.nvim_buf_get_name(buf_number)
            local buf_ft = vim.bo[buf_number].filetype

            if buf_ft == "NvimTree" then
              return false
            end

            if vim.fn.isdirectory(buf_name) == 1 then
              return false
            end

            if buf_name == "" or buf_name:match("/$") then
              return false
            end

            return true
          end,
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              text_align = "left",
              separator = true,
            },
          },
        },
      })
    end,
  },
}
