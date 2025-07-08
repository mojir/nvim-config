return {
  {
    dir = vim.fn.stdpath("config"),
    name = "simple-session",
    config = function()
      local session_dir = vim.fn.stdpath("data") .. "/sessions/"
      vim.fn.mkdir(session_dir, "p")

      -- Configure session options
      vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"

      local function get_session_name()
        local cwd = vim.fn.getcwd()
        return vim.fn.substitute(cwd, "[/\\:]", "_", "g")
      end

      local function get_session_file()
        return session_dir .. get_session_name() .. ".vim"
      end

      local function get_marks_file()
        return session_dir .. get_session_name() .. "_marks.json"
      end

      -- Save global marks (A-Z) to session-specific file
      local function save_session_marks()
        local marks = {}

        -- Save global marks A-Z
        for i = 65, 90 do -- ASCII A-Z
          local mark = string.char(i)
          local pos = vim.fn.getpos("'" .. mark)

          if pos[2] > 0 then -- Valid mark (line number > 0)
            -- Get the buffer number and filename
            local bufnr = pos[1]
            local file = ""

            if bufnr > 0 then
              file = vim.api.nvim_buf_get_name(bufnr)
            else
              -- For marks in non-current buffers, try to get filename differently
              local mark_info = vim.fn.execute("marks " .. mark)
              local filename_match = mark_info:match("%s+%d+%s+%d+%s+(.+)")
              if filename_match then
                file = vim.fn.fnamemodify(filename_match, ":p")
              end
            end

            marks[mark] = {
              line = pos[2],
              col = pos[3],
              file = file,
            }
          end
        end

        local marks_file = get_marks_file()
        local ok, encoded = pcall(vim.fn.json_encode, marks)
        if ok then
          local file = io.open(marks_file, "w")
          if file then
            file:write(encoded)
            file:close()
          end
        end
      end

      -- Load session-specific marks
      local function load_session_marks()
        local marks_file = get_marks_file()

        if vim.fn.filereadable(marks_file) == 0 then
          return
        end

        local file = io.open(marks_file, "r")
        if not file then
          return
        end

        local content = file:read("*a")
        file:close()

        local ok, marks = pcall(vim.fn.json_decode, content)
        if not ok or not marks then
          return
        end

        -- Clear existing global marks first
        for i = 65, 90 do
          local mark = string.char(i)
          pcall(function()
            vim.cmd("delmarks " .. mark)
          end)
        end

        -- Restore session marks
        for mark, data in pairs(marks) do
          if data.file and data.file ~= "" and vim.fn.filereadable(data.file) == 1 then
            -- Open the file and set the mark
            vim.cmd("edit " .. vim.fn.fnameescape(data.file))
            vim.fn.setpos("'" .. mark, { 0, data.line, data.col, 0 })
          end
        end
      end
      -- Clear all global marks (useful when switching sessions)
      local function clear_global_marks()
        for i = 65, 90 do
          local mark = string.char(i)
          vim.cmd("silent! delmarks " .. mark)
        end
      end

      local function save_session()
        -- Close problematic buffers before saving
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) then
            local buftype = vim.bo[buf].buftype
            local name = vim.api.nvim_buf_get_name(buf)

            if buftype == "terminal" or buftype == "help" or buftype == "quickfix" then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            elseif name ~= "" and vim.fn.filereadable(name) == 0 then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
          end
        end

        -- Close nvim-tree before saving
        if pcall(require, "nvim-tree.api") then
          require("nvim-tree.api").tree.close()
        end

        -- Save session-specific marks
        save_session_marks()

        local session_file = get_session_file()
        vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))

        print("Session saved: " .. vim.fn.fnamemodify(session_file, ":t"))
      end

      local function load_session()
        local session_file = get_session_file()
        if vim.fn.filereadable(session_file) == 1 then
          -- Save current session marks before switching
          if vim.fn.argc() == 0 then
            save_session_marks()
          end

          -- Clear current session first
          vim.cmd("silent! %bdelete!")
          clear_global_marks()

          vim.cmd("source " .. vim.fn.fnameescape(session_file))

          -- Load session-specific marks
          vim.defer_fn(function()
            load_session_marks()

            -- Reload nvim-tree after session load
            if pcall(require, "nvim-tree.api") then
              require("nvim-tree.api").tree.reload()
            end
          end, 100)

          print("Session loaded: " .. vim.fn.fnamemodify(session_file, ":t"))
        else
          print("No session found for: " .. get_session_name())
        end
      end

      local function delete_session()
        local session_file = get_session_file()
        local marks_file = get_marks_file()

        local deleted = false
        if vim.fn.filereadable(session_file) == 1 then
          vim.fn.delete(session_file)
          deleted = true
        end

        if vim.fn.filereadable(marks_file) == 1 then
          vim.fn.delete(marks_file)
          deleted = true
        end

        if deleted then
          print("Session deleted: " .. vim.fn.fnamemodify(session_file, ":t"))
        else
          print("No session to delete")
        end
      end

      local function list_sessions()
        local sessions = vim.fn.glob(session_dir .. "*.vim", false, true)
        if #sessions == 0 then
          print("No sessions found")
          return sessions
        end

        print("Available sessions:")
        for _, session in ipairs(sessions) do
          local name = vim.fn.fnamemodify(session, ":t:r")
          local marks_file = session_dir .. name .. "_marks.json"
          local has_marks = vim.fn.filereadable(marks_file) == 1
          print("  " .. name .. (has_marks and " (with marks)" or ""))
        end
        return sessions
      end

      -- Auto-save on exit
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("SimpleSession", { clear = true }),
        callback = function()
          if vim.fn.argc() == 0 then
            save_session()
          end
        end,
      })

      -- Auto-load on start
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("SimpleSessionLoad", { clear = true }),
        callback = function()
          if vim.fn.argc() == 0 then
            vim.defer_fn(function()
              load_session()
            end, 50)
          end
        end,
      })

      -- Auto-save marks when they're modified
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("SessionMarks", { clear = true }),
        callback = function()
          -- Only auto-save marks, not the full session
          save_session_marks()
        end,
      })

      -- Commands
      vim.api.nvim_create_user_command("SessionSave", save_session, { desc = "Save current session" })
      vim.api.nvim_create_user_command("SessionLoad", load_session, { desc = "Load session for current directory" })
      vim.api.nvim_create_user_command(
        "SessionDelete",
        delete_session,
        { desc = "Delete session for current directory" }
      )
      vim.api.nvim_create_user_command("SessionList", list_sessions, { desc = "List all sessions" })

      -- Mark-specific commands
      vim.api.nvim_create_user_command("SessionSaveMarks", save_session_marks, { desc = "Save session marks" })
      vim.api.nvim_create_user_command("SessionLoadMarks", load_session_marks, { desc = "Load session marks" })
      vim.api.nvim_create_user_command("SessionClearMarks", clear_global_marks, { desc = "Clear all global marks" })

      -- Keymaps
      vim.keymap.set("n", "<leader>ss", save_session, { desc = "Save session" })
      vim.keymap.set("n", "<leader>sl", load_session, { desc = "Load session" })
      vim.keymap.set("n", "<leader>sd", delete_session, { desc = "Delete session" })

      -- Session picker with Telescope
      local function session_picker()
        local sessions = vim.fn.glob(session_dir .. "*.vim", false, true)

        if #sessions == 0 then
          print("No sessions found")
          return
        end

        local ok = pcall(require, "telescope")
        if not ok then
          list_sessions()
          return
        end

        local session_items = {}
        for _, session in ipairs(sessions) do
          local name = vim.fn.fnamemodify(session, ":t:r")
          local marks_file = session_dir .. name .. "_marks.json"
          local has_marks = vim.fn.filereadable(marks_file) == 1
          table.insert(session_items, {
            name = name,
            display = name .. (has_marks and " (marks)" or ""),
          })
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Sessions",
            finder = require("telescope.finders").new_table({
              results = session_items,
              entry_maker = function(entry)
                return {
                  value = entry.name,
                  display = entry.display,
                  ordinal = entry.name,
                }
              end,
            }),
            sorter = require("telescope.config").values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
              require("telescope.actions").select_default:replace(function()
                local selection = require("telescope.actions.state").get_selected_entry()
                require("telescope.actions").close(prompt_bufnr)

                if selection then
                  -- Save current marks before switching
                  save_session_marks()

                  local session_file = session_dir .. selection.value .. ".vim"
                  vim.cmd("silent! %bdelete!")
                  clear_global_marks()
                  vim.cmd("source " .. vim.fn.fnameescape(session_file))

                  vim.defer_fn(function()
                    load_session_marks()
                  end, 100)

                  print("Loaded session: " .. selection.value)
                end
              end)
              return true
            end,
          })
          :find()
      end

      vim.keymap.set("n", "<leader>sp", session_picker, { desc = "Pick session (Telescope)" })
    end,
  },
}
