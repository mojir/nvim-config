local config = require("lits.config")
local state = require("lits.state")
local utils = require("lits.utils")
local ui = require("lits.ui")
local files = require("lits.files")

local M = {}

local function open_lits_playground()
  local base_url = "https://mojir.github.io/lits/"
  local current_state = state.get()

  -- Get current editor content
  local current_content = ""
  if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
    local content_lines = vim.api.nvim_buf_get_lines(current_state.editor_buf, 0, -1, false)
    current_content = "// Coming from NeoVim Lits plugin\n" .. table.concat(content_lines, "\n")
  end

  -- Create JSON object
  local json_obj = vim.fn.json_encode({ ["lits-code"] = current_content })

  -- Encode like JavaScript's btoa(encodeURIComponent(json))
  local uri_encoded = vim.fn
    .system(
      "printf '%s' "
        .. vim.fn.shellescape(json_obj)
        .. " | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=\"\"))'"
    )
    :gsub("\n$", "")
  local base64_encoded = vim.fn.system("printf '%s' " .. vim.fn.shellescape(uri_encoded) .. " | base64"):gsub("\n$", "")

  -- Build final URL
  local url = base_url .. "?state=" .. base64_encoded

  vim.fn.system("open " .. vim.fn.shellescape(url))
  print("Opened Lits documentation with current code")
end

local function show_help()
  local help_lines = {
    "Lits Editor Help:",
    "",
    "Evaluation:",
    "  <leader><CR> - Evaluate and insert result directly",
    "  <leader>e    - Evaluate and preview result",
    "",
    "File Operations:",
    "  <leader>s - Save As (prompts for filename)",
    "  <leader>o - Open file (Telescope picker)",
    "  <leader>n - New file",
    "  <leader>d - Delete current file",
    "  <leader>f - Open folder in Finder",
    "",
    "Other:",
    "  <leader>b - Open content in new buffer",
    "  <leader>l - Open Lits Playground with current code",
    "  <Esc>     - Close editor",
    "  <leader>? - Show this help",
    "",
    "Note: Files auto-save when closing editor",
    "",
    "In result popup:",
    "  i         - Insert result at cursor",
    "  y         - Copy result to clipboard",
    "  q/<Esc>   - Cancel and return to editor",
  }
  print(table.concat(help_lines, "\n"))
end

local function should_close_editor()
  vim.defer_fn(function()
    local current_state = state.get()
    if current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win) then
      local current_win = vim.api.nvim_get_current_win()
      -- Close if we're in a window that's not part of Lits
      if current_win ~= current_state.editor_win and current_win ~= current_state.result_win then
        ui.close_editor()
      end
    end
  end, 100)
end

local function open_content_in_new_buffer()
  local current_state = state.get()
  local editor_buf = current_state.editor_buf

  if not (editor_buf and vim.api.nvim_buf_is_valid(editor_buf)) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(editor_buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- Close editor and return to original window
  ui.close_editor()
  if current_state.original_win and vim.api.nvim_win_is_valid(current_state.original_win) then
    vim.api.nvim_set_current_win(current_state.original_win)
  end

  -- Create new buffer with lits content
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(content, "\n"))
  vim.bo.filetype = "javascript"

  print("Lits content opened in new buffer")
end

function M.evaluate_and_show()
  local success, result_text = utils.evaluate_lits()
  if success then
    require("lits.result").create_popup(result_text, true)
  else
    require("lits.result").create_popup(result_text, false)
  end
end

function M.evaluate_and_insert()
  local success, result_text = utils.evaluate_lits()
  if success then
    ui.close_editor_and_return_to_original()
    vim.api.nvim_put({ result_text }, "c", true, true)
  else
    require("lits.result").create_popup(result_text, false)
  end
end

local function create_program_window(content)
  content = content or ""
  local width, height = utils.calculate_window_size(content)
  local current_state = state.get()

  -- Create buffer
  local editor_buf = vim.api.nvim_create_buf(false, true)
  state.set("editor_buf", editor_buf)

  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(editor_buf, 0, -1, false, lines)
  vim.bo[editor_buf].filetype = "javascript"

  -- Create window
  local editor_win = vim.api.nvim_open_win(editor_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = config.get().popup.border,
    title = string.format(" Lits Editor (%s) ", current_state.current_file),
    title_pos = "center",
  })
  state.set("editor_win", editor_win)

  -- Enable line numbers for the editor window
  vim.wo[editor_win].number = true

  -- Set up keymaps
  local opts = { buffer = editor_buf, noremap = true, silent = true, nowait = true }

  -- Evaluation
  vim.keymap.set("n", "<leader><CR>", M.evaluate_and_insert, opts)
  vim.keymap.set("n", "<leader>e", M.evaluate_and_show, opts)

  -- File operations
  vim.keymap.set("n", "<leader>s", files.save_as_dialog, opts)
  vim.keymap.set("n", "<leader>o", files.open_file_picker, opts)
  vim.keymap.set("n", "<leader>n", files.new_file_dialog, opts)
  vim.keymap.set("n", "<leader>d", files.delete_current_file, opts)
  vim.keymap.set("n", "<leader>f", files.copy_current_file_path, opts)

  -- Open content in new buffer
  vim.keymap.set("n", "<leader>b", open_content_in_new_buffer, opts)

  -- Other operations
  vim.keymap.set("n", "<leader>l", open_lits_playground, opts)
  vim.keymap.set("n", "<Esc>", ui.close_editor, opts)
  vim.keymap.set("n", "<leader>?", show_help, opts)

  -- Close window when clicking outside
  vim.api.nvim_create_autocmd("WinLeave", {
    group = current_state.autocmd_group,
    buffer = editor_buf,
    callback = should_close_editor,
  })
end

function M.open(use_selection)
  -- Wait for initialization if needed
  if not state.is_initialized() then
    vim.notify("Lits plugin is still initializing, please wait...", vim.log.levels.WARN)
    return
  end

  -- Store original position and window
  state.set("original_win", vim.api.nvim_get_current_win())
  state.set("original_cursor_pos", vim.api.nvim_win_get_cursor(state.get().original_win))

  local content = ""
  local current_state = state.get()

  if use_selection then
    local selection = utils.get_visual_selection()
    if selection == "" then
      vim.notify("No valid selection found", vim.log.levels.WARN)
      return
    end

    -- Always use default file for selections
    local target_file = config.get().default_file
    local existing_content = utils.load_program(target_file)

    if existing_content ~= "" then
      local choice = vim.fn.confirm(string.format("Replace existing %s content?", target_file), "&Yes\n&No", 2)

      if choice == 1 then
        content = selection
      else
        content = existing_content
      end
    else
      content = selection
    end

    -- Update current file
    state.set("current_file", target_file)
  else
    -- Load the appropriate starting file
    local starting_file = files.get_starting_file()
    content = utils.load_program(starting_file)
    state.set("current_file", starting_file)
  end

  state.set("current_program", content)
  create_program_window(content)
end
return M
