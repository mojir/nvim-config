return {
  -- Various text objects
  {
    'chrisgrieser/nvim-various-textobjs',
    enabled = true,
    config = function()
      require('various-textobjs').setup({
        keymaps = { useDefaults = true },
        disabledDefaults = { "!" },
        forwardLooking = {},
        notify = {},
        textobjs = {},
        debug = false,
        behavior = {}
      })
    end
  }
}

