-- Improved toggleterm.lua configuration with better code quality
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      -- Constants
      local CURSOR_RESTORE_DELAY = 0
      local TERMINAL_CLOSE_DELAY = 0
      local VISUAL_BLOCK_MODE = "\22" -- Ctrl-V

      -- Module state (avoid global pollution)
      local M = {
        float_term = nil,
        terminal_state = {
          original_mode = nil,
          original_selection = nil,
          original_cursor = nil,
          original_win = nil,
        }
      }

      require("toggleterm").setup({
        size = 15,
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = false,
        persist_size = true,
        direction = "horizontal",
        close_on_exit = true,
        shell = vim.o.shell,
        auto_scroll = true,
        on_exit = function(terminal)
          if terminal.job_id then
            vim.fn.jobstop(terminal.job_id)
          end
          if terminal.bufnr and vim.api.nvim_buf_is_valid(terminal.bufnr) then
            vim.api.nvim_buf_delete(terminal.bufnr, { force = true })
          end
        end,
        on_create = function(_)
          vim.opt_local.scrolloff = 0
          vim.opt_local.sidescrolloff = 0
        end,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })

      -- Helper functions
      local function safe_call(func, ...)
        local ok, result = pcall(func, ...)
        return ok and result
      end

      local function is_visual_mode(mode)
        return mode:match("^[vV" .. VISUAL_BLOCK_MODE .. "]")
      end

      local function save_visual_selection(mode)
        local current_cursor = vim.api.nvim_win_get_cursor(0)
        
        -- For visual block mode, get virtual column BEFORE escaping
        local cursor_virtcol = nil
        if mode == VISUAL_BLOCK_MODE then
          cursor_virtcol = vim.fn.virtcol(".")
        end
        
        -- Force update of visual marks
        vim.cmd("normal! \27") -- Escape
        
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        
        local selection = {
          mode = mode,
          start_pos = start_pos,
          end_pos = end_pos,
          start_line = start_pos[2],
          start_col = start_pos[3],
          end_line = end_pos[2],
          end_col = end_pos[3],
          cursor_line = current_cursor[1],
          cursor_col = current_cursor[2],
        }

        -- Add virtual column info for visual block mode
        if mode == VISUAL_BLOCK_MODE then
          selection.cursor_virtcol = cursor_virtcol  -- Use the one saved before escape
          selection.start_virtcol = vim.fn.virtcol("'<")
          selection.end_virtcol = vim.fn.virtcol("'>")
        end

        return selection
      end

      local function restore_visual_block_mode(sel)
        if not (sel.start_virtcol and sel.end_virtcol and sel.cursor_virtcol) then
          return false
        end

        -- Move to start position using virtual column
        vim.cmd(string.format("normal! %dG%d|", sel.start_line, sel.start_virtcol))
        
        -- Enter visual block mode
        vim.cmd("normal! " .. VISUAL_BLOCK_MODE)
        
        -- Move to end position using virtual column
        vim.cmd(string.format("normal! %dG%d|", sel.end_line, sel.end_virtcol))
        
        -- Move cursor to original virtual column position (this is the key fix)
        vim.cmd(string.format("normal! %dG%d|", sel.cursor_line, sel.cursor_virtcol))
        
        return true
      end

      local function restore_regular_visual_mode(sel)
        local mode_config = {
          ["v"] = {sel.end_line, sel.end_col - 1},
          ["V"] = {sel.end_line, 0},
          [VISUAL_BLOCK_MODE] = {sel.end_line, sel.end_col - 1}
        }

        safe_call(vim.api.nvim_win_set_cursor, 0, {sel.start_line, sel.start_col - 1})
        vim.cmd("normal! " .. sel.mode)
        
        local end_pos = mode_config[sel.mode]
        if end_pos then
          safe_call(vim.api.nvim_win_set_cursor, 0, end_pos)
        end

        if sel.cursor_line and sel.cursor_col then
          safe_call(vim.api.nvim_win_set_cursor, 0, {sel.cursor_line, sel.cursor_col})
        end
      end

      local function restore_visual_selection(sel)
        if not (sel and sel.start_line and sel.end_line and sel.start_col and sel.end_col and sel.mode) then
          return
        end

        if sel.mode == VISUAL_BLOCK_MODE and restore_visual_block_mode(sel) then
          return
        end

        restore_regular_visual_mode(sel)
      end

      local function restore_window_and_cursor()
        if not (M.terminal_state.original_win and vim.api.nvim_win_is_valid(M.terminal_state.original_win)) then
          return false
        end

        safe_call(vim.api.nvim_set_current_win, M.terminal_state.original_win)
        
        if M.terminal_state.original_cursor then
          safe_call(vim.api.nvim_win_set_cursor, 0, M.terminal_state.original_cursor)
        end

        return true
      end

      local function restore_mode()
        local mode = M.terminal_state.original_mode
        if not mode then return end

        if M.terminal_state.original_selection then
          restore_visual_selection(M.terminal_state.original_selection)
        elseif mode == "i" then
          vim.cmd("startinsert")
        elseif mode == "R" then
          vim.cmd("startreplace")
        end
      end

      local function cleanup_state()
        M.terminal_state = {
          original_mode = nil,
          original_selection = nil,
          original_cursor = nil,
          original_win = nil,
        }
      end

      local function save_state()
        M.terminal_state.original_win = vim.api.nvim_get_current_win()
        M.terminal_state.original_cursor = vim.api.nvim_win_get_cursor(0)
        
        local mode = vim.fn.mode()
        M.terminal_state.original_mode = mode
        
        if is_visual_mode(mode) then
          M.terminal_state.original_selection = save_visual_selection(mode)
        else
          M.terminal_state.original_selection = nil
        end
      end

      local function restore_state()
        vim.defer_fn(function()
          if restore_window_and_cursor() then
            vim.defer_fn(function()
              restore_mode()
              cleanup_state()
            end, CURSOR_RESTORE_DELAY)
          end
        end, TERMINAL_CLOSE_DELAY)
      end

      -- Terminal management
      local function safe_wqall()
        vim.cmd("wall")
        
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
            local job_id = vim.b[buf].terminal_job_id
            if job_id then
              vim.fn.jobstop(job_id)
            end
            safe_call(vim.api.nvim_buf_delete, buf, { force = true })
          end
        end
        
        vim.cmd("qall")
      end

      -- Global keymaps and functions
      function _G.set_terminal_keymaps()
        local opts = { buffer = 0, noremap = true, silent = true }
        
        -- Navigation
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
        
        -- Mode keymaps
        vim.keymap.set("n", "i", "i", { buffer = 0 })
        vim.keymap.set("n", "a", "a", { buffer = 0 })

        -- Terminal control
        local function close_terminal()
          if M.float_term then
            M.float_term:close()
          else
            vim.cmd("close")
          end
        end

        vim.keymap.set("n", "<esc>", close_terminal, { buffer = 0, desc = "Close terminal" })
        vim.keymap.set("t", "<C-t>", close_terminal, opts)
        vim.keymap.set("n", "<C-t>", close_terminal, opts)

        -- File opening
        vim.keymap.set("n", "gf", function()
          local filename = vim.fn.expand("<cfile>")
          if filename ~= "" then
            close_terminal()
            vim.cmd("edit " .. filename)
          end
        end, { buffer = 0, desc = "Open file under cursor" })
      end

      vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

      -- Create terminal
      local Terminal = require("toggleterm.terminal").Terminal
      M.float_term = Terminal:new({
        direction = "float",
        hidden = true,
        on_close = restore_state,
      })

      function _G._ENHANCED_FLOAT_TOGGLE()
        if M.float_term:is_open() then
          M.float_term:close()
        else
          save_state()
          M.float_term:open()
          vim.defer_fn(function()
            if vim.bo.buftype == "terminal" then
              vim.cmd("startinsert")
            end
          end, CURSOR_RESTORE_DELAY)
        end
      end

      -- Backwards compatibility
      function _FLOAT_TOGGLE()
        _G._ENHANCED_FLOAT_TOGGLE()
      end

      -- Commands and keymaps
      _G.safe_wqall = safe_wqall  -- Export globally for use in keybindings
      vim.api.nvim_create_user_command("Wqall", safe_wqall, { bang = true, desc = "Write and quit all (terminal safe)" })
      vim.cmd("cabbrev wqall Wqall")
      
      vim.keymap.set({"n", "v", "i"}, "<C-t>", _G._ENHANCED_FLOAT_TOGGLE, { desc = "Toggle floating terminal with state restoration" })
      
      -- Cleanup
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("TerminalCleanup", { clear = true }),
        callback = function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
              local job_id = vim.b[buf].terminal_job_id
              if job_id then
                vim.fn.jobstop(job_id)
              end
            end
          end
        end,
      })
    end,
  },
}
