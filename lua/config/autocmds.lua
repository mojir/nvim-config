-- Auto-save buffers
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command("silent! write")
    end
  end,
})

-- Clear duplicate tracking when diagnostics are refreshed
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "LspAttach" }, {
  callback = function(args)
    if not _G.diagnostic_tracker then
      _G.diagnostic_tracker = { seen = {}, buffer_generation = {} }
    end

    local bufnr = args.buf or vim.api.nvim_get_current_buf()
    _G.diagnostic_tracker.buffer_generation[bufnr] = (_G.diagnostic_tracker.buffer_generation[bufnr] or 0) + 1

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
    vim.opt_local.formatoptions:remove({ "o" })
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "FocusGained" }, {
  callback = function()
    if not os.getenv("TERM_PROGRAM") then
      return
    end

    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
    io.write("\027]0;" .. "NeoVim@" .. cwd .. "\007")
    io.flush()
  end,
})

-- Reset window title when exiting NeoVim
vim.api.nvim_create_autocmd({ "VimLeave" }, {
  callback = function()
    local term = os.getenv("TERM") or ""
    if term == "" then
      return
    end

    -- Reset to just the current directory name
    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    io.write("\027]0;" .. cwd .. "\007")
    io.flush()
  end,
})

-- Set filetype for .conf and .config files to dosini
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.conf", "*.config" },
  callback = function()
    vim.bo.filetype = "config"
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SessionCleanup", { clear = true }),
  callback = function()
    -- Close all terminal buffers before session save
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})
