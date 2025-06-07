-- Auto-save buffers
vim.api.nvim_create_autocmd({"FocusLost", "BufLeave", "CursorHold", "CursorHoldI"}, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command('silent! write')
    end
  end,
})

-- Auto-remove trailing spaces on save instead of showing warnings
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Clear duplicate tracking when diagnostics are refreshed
vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost", "LspAttach"}, {
  callback = function(args)
    if not _G.diagnostic_tracker then
      _G.diagnostic_tracker = { seen = {}, buffer_generation = {} }
    end

    local bufnr = args.buf or vim.api.nvim_get_current_buf()
    _G.diagnostic_tracker.buffer_generation[bufnr] =
      (_G.diagnostic_tracker.buffer_generation[bufnr] or 0) + 1

    for key, _ in pairs(_G.diagnostic_tracker.seen) do
      if key:match("^" .. bufnr .. ":") then
        _G.diagnostic_tracker.seen[key] = nil
      end
    end
  end,
})

-- Force disable comment continuation on every buffer
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.opt_local.formatoptions:remove({ 'o' })
  end,
})
