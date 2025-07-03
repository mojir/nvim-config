-- lua/lits.lua
local M = {}

-- Default configuration
local default_config = {
  programs_dir = vim.fn.stdpath("data") .. "/lits-programs/",
  default_file = "DEFAULT.lits",
  popup = {
    min_width = 60,
    min_height = 15,
    max_width_ratio = 0.8,
    max_height_ratio = 0.8,
    max_line_width_ratio = 0.6, -- Prevent extremely wide windows
    border = "rounded",
  },
}

-- State management
local state = {
  config = {},
  current_program = "",
  last_result = "",
  current_file = "",
  editor_buf = nil,
  editor_win = nil,
  result_buf = nil,
  result_win = nil,
  original_cursor_pos = nil,
  original_win = nil,
  autocmd_group = nil,
  initialized = false,
}

-- Utility functions
local function ensure_programs_dir()
  local ok, err = pcall(vim.fn.mkdir, state.config.programs_dir, "p")
  if not ok then
    vim.notify("Failed to create lits programs directory: " .. err, vim.log.levels.ERROR)
    return false
  end
  return true
end

local function get_program_path(filename)
  filename = filename or state.current_file
  return state.config.programs_dir .. filename
end

local function load_program(filename)
  filename = filename or state.current_file
  local filepath = get_program_path(filename)

  local ok, content = pcall(function()
    if vim.fn.filereadable(filepath) == 1 then
      return table.concat(vim.fn.readfile(filepath), "\n")
    end
    return ""
  end)

  if not ok then
    vim.notify("Failed to load program: " .. filename, vim.log.levels.WARN)
    return ""
  end

  return content
end

local function save_program(content, filename)
  filename = filename or state.current_file

  if not ensure_programs_dir() then
    return false
  end

  local filepath = get_program_path(filename)

  local ok, err = pcall(function()
    local lines = vim.split(content, "\n")
    vim.fn.writefile(lines, filepath)
  end)

  if not ok then
    vim.notify("Failed to save program: " .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

local function get_visual_selection()
  local mode = vim.fn.visualmode()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    return ""
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

  if #lines == 0 then
    return ""
  end

  if mode == "V" then
    -- Line-wise selection - use full lines
    return table.concat(lines, "\n")
  elseif mode == "\22" then -- Ctrl-V (block selection)
    -- Block selection - extract rectangle
    local result_lines = {}
    for i, line in ipairs(lines) do
      local start_col = (i == 1) and start_pos[3] or start_pos[3]
      local end_col = (i == #lines) and end_pos[3] or end_pos[3]

      if start_col <= #line then
        local extracted = string.sub(line, start_col, math.min(end_col, #line))
        table.insert(result_lines, extracted)
      else
        table.insert(result_lines, "")
      end
    end
    return table.concat(result_lines, "\n")
  else
    -- Character-wise selection
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    else
      lines[1] = string.sub(lines[1], start_pos[3])
      lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
    return table.concat(lines, "\n")
  end
end

local function calculate_window_size(content)
  local lines = vim.split(content or "", "\n")

  -- Handle empty content
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    return state.config.popup.min_width, state.config.popup.min_height
  end

  -- Calculate content dimensions with limits
  local max_line_width = math.floor(vim.o.columns * state.config.popup.max_line_width_ratio)
  local content_width = 0

  for _, line in ipairs(lines) do
    local line_width = math.min(vim.fn.strdisplaywidth(line), max_line_width)
    content_width = math.max(content_width, line_width)
  end

  local content_height = #lines

  -- Apply constraints
  local max_width = math.floor(vim.o.columns * state.config.popup.max_width_ratio)
  local max_height = math.floor(vim.o.lines * state.config.popup.max_height_ratio)

  local width = math.max(state.config.popup.min_width, math.min(content_width + 4, max_width))
  local height = math.max(state.config.popup.min_height, math.min(content_height + 2, max_height))

  return width, height
end

local function validate_filepath(filepath)
  -- Basic validation - ensure it's within our programs directory
  local programs_dir = vim.fn.resolve(state.config.programs_dir)
  local resolved_path = vim.fn.resolve(filepath)

  return resolved_path:sub(1, #programs_dir) == programs_dir
end

local function evaluate_lits()
  -- Check if lits command exists
  local handle = io.popen("command -v lits >/dev/null 2>&1 && echo 'exists'")
  local lits_exists = handle and handle:read("*a"):match("exists")
  if handle then
    handle:close()
  end

  if not lits_exists then
    return false, "lits command not found. Please ensure lits is installed and in PATH."
  end

  local filepath = get_program_path(state.current_file)

  -- Validate filepath for security
  if not validate_filepath(filepath) then
    return false, "Invalid file path for security reasons."
  end

  -- Save current content before evaluation
  if state.editor_buf and vim.api.nvim_buf_is_valid(state.editor_buf) then
    local lines = vim.api.nvim_buf_get_lines(state.editor_buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    if not save_program(content, state.current_file) then
      return false, "Failed to save program before evaluation."
    end
  end

  local cmd = string.format("NO_COLOR=1 lits -f %s 2>&1", vim.fn.shellescape(filepath))
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code == 0 then
    -- Clean up result (remove trailing newline if present)
    result = result:gsub("\n$", "")
    state.last_result = result
    return true, result
  else
    return false, string.format("Lits evaluation failed (exit code %d):\n%s", exit_code, result)
  end
end

local function cleanup_state()
  -- Clear autocmds
  if state.autocmd_group then
    pcall(vim.api.nvim_del_augroup_by_id, state.autocmd_group)
    state.autocmd_group = nil
  end

  -- Close windows and clean buffers
  if state.result_win and vim.api.nvim_win_is_valid(state.result_win) then
    pcall(vim.api.nvim_win_close, state.result_win, true)
  end
  if state.result_buf and vim.api.nvim_buf_is_valid(state.result_buf) then
    pcall(vim.api.nvim_buf_delete, state.result_buf, { force = true })
  end

  if state.editor_win and vim.api.nvim_win_is_valid(state.editor_win) then
    pcall(vim.api.nvim_win_close, state.editor_win, true)
  end
  if state.editor_buf and vim.api.nvim_buf_is_valid(state.editor_buf) then
    pcall(vim.api.nvim_buf_delete, state.editor_buf, { force = true })
  end

  -- Reset state
  state.result_win = nil
  state.result_buf = nil
  state.editor_win = nil
  state.editor_buf = nil
end

local function close_result_popup()
  -- Only close the result popup
  if state.result_win and vim.api.nvim_win_is_valid(state.result_win) then
    pcall(vim.api.nvim_win_close, state.result_win, true)
    state.result_win = nil
  end
  if state.result_buf and vim.api.nvim_buf_is_valid(state.result_buf) then
    pcall(vim.api.nvim_buf_delete, state.result_buf, { force = true })
    state.result_buf = nil
  end

  -- Return focus to editor window if it exists
  if state.editor_win and vim.api.nvim_win_is_valid(state.editor_win) then
    vim.api.nvim_set_current_win(state.editor_win)
  end
end

local function close_editor()
  if state.editor_win and vim.api.nvim_win_is_valid(state.editor_win) then
    -- Auto-save on close if content changed
    if state.editor_buf and vim.api.nvim_buf_is_valid(state.editor_buf) then
      local lines = vim.api.nvim_buf_get_lines(state.editor_buf, 0, -1, false)
      local content = table.concat(lines, "\n")
      if content ~= state.current_program then
        save_program(content, state.current_file)
        state.current_program = content
      end
    end

    pcall(vim.api.nvim_win_close, state.editor_win, true)
    state.editor_win = nil
  end

  if state.editor_buf and vim.api.nvim_buf_is_valid(state.editor_buf) then
    pcall(vim.api.nvim_buf_delete, state.editor_buf, { force = true })
    state.editor_buf = nil
  end
end

local function close_editor_and_return_to_original()
  close_editor()

  -- Restore original window and cursor position
  if state.original_win and vim.api.nvim_win_is_valid(state.original_win) then
    vim.api.nvim_set_current_win(state.original_win)
    if state.original_cursor_pos then
      pcall(vim.api.nvim_win_set_cursor, state.original_win, state.original_cursor_pos)
    end
  end
end

local function create_result_popup(result, show_insert_option)
  close_result_popup()

  local result_lines = vim.split(result, "\n")
  local width, height = calculate_window_size(result)

  -- Create buffer
  state.result_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.result_buf, 0, -1, false, result_lines)
  vim.bo[state.result_buf].readonly = true
  vim.bo[state.result_buf].modifiable = false
  vim.bo[state.result_buf].filetype = "text"

  -- Add help text if insert option is available
  if show_insert_option then
    vim.bo[state.result_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.result_buf, -1, -1, false, {
      "",
      "(i)nsert  (y)ank  (q)uit",
    })
    vim.bo[state.result_buf].modifiable = false
  end

  -- Create window
  state.result_win = vim.api.nvim_open_win(state.result_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = state.config.popup.border,
    title = " Lits Result ",
    title_pos = "center",
  })

  -- Ensure we're in normal mode and focused on our buffer
  vim.cmd("stopinsert")
  vim.api.nvim_set_current_buf(state.result_buf)

  -- Set up keymaps
  local opts = { buffer = state.result_buf, noremap = true, silent = true, nowait = true }

  -- QUIT/CANCEL options - return to editor
  vim.keymap.set("n", "q", close_result_popup, opts)

  if show_insert_option then
    -- INSERT option - insert result at original position
    vim.keymap.set("n", "i", function()
      close_result_popup()
      close_editor_and_return_to_original()
      vim.api.nvim_put({ state.last_result }, "c", true, true)
    end, opts)

    -- Enter key also inserts
    vim.keymap.set("n", "<CR>", function()
      close_result_popup()
      close_editor_and_return_to_original()
      vim.api.nvim_put({ state.last_result }, "c", true, true)
    end, opts)

    -- YANK option - copy to clipboard and return to editor
    vim.keymap.set("n", "y", function()
      vim.fn.setreg("+", state.last_result)
      vim.fn.setreg('"', state.last_result)
      print("Result copied to clipboard")
      close_result_popup()
    end, opts)
  end
end

local function evaluate_and_show()
  local success, result = evaluate_lits()
  if success then
    create_result_popup(result, true)
  else
    create_result_popup(result, false)
  end
end

local function evaluate_and_insert()
  local success, result = evaluate_lits()
  if success then
    close_editor_and_return_to_original()
    vim.api.nvim_put({ result }, "c", true, true)
  else
    create_result_popup(result, false)
  end
end

local function create_program_window(content)
  content = content or ""
  local width, height = calculate_window_size(content)

  -- Create buffer
  state.editor_buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(state.editor_buf, 0, -1, false, lines)
  vim.bo[state.editor_buf].filetype = "lisp" -- Close enough for basic syntax highlighting

  -- Create window
  state.editor_win = vim.api.nvim_open_win(state.editor_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = state.config.popup.border,
    title = string.format(" Lits Editor (%s) ", state.current_file),
    title_pos = "center",
  })

  -- Enable line numbers for the editor window
  vim.wo[state.editor_win].number = true

  -- Set up keymaps
  local opts = { buffer = state.editor_buf, noremap = true, silent = true }

  vim.keymap.set("n", "q", close_editor, opts)
  vim.keymap.set("n", "<C-e>", evaluate_and_show, opts)
  vim.keymap.set("i", "<C-e>", evaluate_and_show, opts)
  vim.keymap.set("n", "<C-CR>", evaluate_and_insert, opts)
  vim.keymap.set("i", "<C-CR>", evaluate_and_insert, opts)
  vim.keymap.set("i", "<C-c>", function()
    -- Clear all content
    vim.api.nvim_buf_set_lines(state.editor_buf, 0, -1, false, { "" })
  end, opts)
  vim.keymap.set("n", "<C-c>", function()
    -- Clear all content
    vim.api.nvim_buf_set_lines(state.editor_buf, 0, -1, false, { "" })
  end, opts)
  vim.keymap.set("n", "d", function()
    local url = "https://mojir.github.io/lits/"
    vim.fn.system("open " .. vim.fn.shellescape(url))
    print("Opened Lits documentation in browser")
  end, opts)
  -- Close window when clicking outside
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = state.editor_buf,
    once = true,
    callback = function()
      vim.defer_fn(function()
        -- Only close if the editor window still exists and we're not in result popup
        if state.editor_win and vim.api.nvim_win_is_valid(state.editor_win) and not state.result_win then
          close_editor()

          vim.cmd("stopinsert")
        end
      end, 50)
    end,
  })
  -- Help binding
  vim.keymap.set("n", "?", function()
    local help_lines = {
      "Lits Editor Help:",
      "",
      "<C-e>     - Evaluate and preview result",
      "<C-Enter> - Evaluate and insert result directly",
      "<C-c>     - Clear editor content",
      "d         - Open Lits documentation",
      "q         - Close editor",
      "?         - Show this help",
      "",
      "In result popup:",
      "i/<Enter> - Insert result at cursor",
      "y         - Copy result to clipboard",
      "q         - Cancel and return to editor",
    }
    print(table.concat(help_lines, "\n"))
  end, opts)

  -- Enter insert mode
  vim.cmd("startinsert")
end

local function open_lits_editor(use_selection)
  -- Wait for initialization if needed
  if not state.initialized then
    vim.notify("Lits plugin is still initializing, please wait...", vim.log.levels.WARN)
    return
  end

  -- Store original position and window
  state.original_win = vim.api.nvim_get_current_win()
  state.original_cursor_pos = vim.api.nvim_win_get_cursor(state.original_win)

  local content = ""

  if use_selection then
    local selection = get_visual_selection()
    if selection == "" then
      vim.notify("No valid selection found", vim.log.levels.WARN)
      return
    end

    local existing_content = load_program(state.current_file)

    if existing_content ~= "" then
      local choice = vim.fn.confirm(string.format("Replace existing %s content?", state.current_file), "&Yes\n&No", 2)

      if choice == 1 then
        content = selection
      else
        content = existing_content
      end
    else
      content = selection
    end
  else
    content = load_program(state.current_file)
  end

  state.current_program = content
  create_program_window(content)
end

-- Public API
function M.setup(opts)
  opts = opts or {}

  -- Merge with defaults
  state.config = vim.tbl_deep_extend("force", default_config, opts)
  state.current_file = state.config.default_file

  -- Create main autocmd group
  state.autocmd_group = vim.api.nvim_create_augroup("LitsPlugin", { clear = true })

  -- Initialize directory and load default program
  vim.defer_fn(function()
    if ensure_programs_dir() then
      state.current_program = load_program(state.current_file)
      state.initialized = true
    else
      vim.notify("Failed to initialize Lits plugin", vim.log.levels.ERROR)
    end
  end, 10) -- Reduced delay

  -- Setup cleanup on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = state.autocmd_group,
    callback = cleanup_state,
  })

  -- Commands
  vim.api.nvim_create_user_command("Lits", function(cmd_opts)
    if cmd_opts.range == 2 then
      -- Called from visual mode
      open_lits_editor(true)
    else
      -- Called from normal mode
      open_lits_editor(false)
    end
  end, {
    range = true,
    desc = "Open Lits program editor",
  })

  -- Optional: Add keymaps for quick access
  vim.keymap.set("n", "<leader>L", ":Lits<CR>", { desc = "Open Lits editor" })
  vim.keymap.set("v", "<leader>L", ":Lits<CR>", { desc = "Open Lits editor with selection" })
end

return M
