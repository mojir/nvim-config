return {
  -- Various text objects
  {
    'chrisgrieser/nvim-various-textobjs',
    config = function()
      require('various-textobjs').setup({
        keymaps = { useDefaults = true },
        forwardLooking = {},
        notify = {},
        textobjs = {},
        debug = false,
        behavior = {}
      })
    end
  }
}

