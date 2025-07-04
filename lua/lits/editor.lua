-- lua/lits/editor.lua
local config = require("lits.config")
local state = require("lits.state")
local utils = require("lits.utils")
local ui = require("lits.ui")
local result = require("lits.result")

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
    "<C-Enter> - Evaluate and insert result directly",
    "<C-e>     - Evaluate and preview result",
    "<C-q> / q - Close editor",
    "<C-l>     - Open Lits Playground with current code",
    "<C-s>     - Save current program",
    "?         - Show this help",
    "",
    "In result popup:",
    "i/<Enter> - Insert result at cursor",
    "y         - Copy result to clipboard",
    "q         - Cancel and return to editor",
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

function M.evaluate_and_show()
  local success, result_text = utils.evaluate_lits()
  if success then
    result.create_popup(result_text, true)
  else
    result.create_popup(result_text, false)
  end
end

function M.evaluate_and_insert()
  local success, result_text = utils.evaluate_lits()
  if success then
    ui.close_editor_and_return_to_original()
    vim.api.nvim_put({ result_text }, "c", true, true)
  else
    result.create_popup(result_text, false)
  end
end

function M.save_current_program()
  local current_state = state.get()
  if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
    local lines = vim.api.nvim_buf_get_lines(current_state.editor_buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    if utils.save_program(content, current_state.current_file) then
      state.set("current_program", content)
      print("Program saved: " .. current_state.current_file)
      return true
    else
      print("Failed to save program")
      return false
    end
  end
  print("No program to save")
  return false
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
  vim.bo[editor_buf].filetype = "lisp" -- Close enough for basic syntax highlighting

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
  local opts = { buffer = editor_buf, noremap = true, silent = true }

  vim.keymap.set("n", "<C-CR>", M.evaluate_and_insert, opts)
  vim.keymap.set("i", "<C-CR>", M.evaluate_and_insert, opts)
  vim.keymap.set("n", "<C-e>", M.evaluate_and_show, opts)
  vim.keymap.set("i", "<C-e>", M.evaluate_and_show, opts)
  vim.keymap.set("i", "<C-l>", open_lits_playground, opts)
  vim.keymap.set("n", "<C-l>", open_lits_playground, opts)
  vim.keymap.set("n", "<C-s>", M.save_current_program, opts)
  vim.keymap.set("i", "<C-s>", M.save_current_program, opts)
  vim.keymap.set("n", "q", ui.close_editor, opts)
  vim.keymap.set("n", "<C-q>", ui.close_editor, opts)
  vim.keymap.set("i", "<C-q>", function()
    vim.cmd("stopinsert")
    ui.close_editor()
  end, opts)
  vim.keymap.set("n", "?", show_help, opts)

  -- Close window when clicking outside
  vim.api.nvim_create_autocmd("WinLeave", {
    group = current_state.autocmd_group,
    buffer = editor_buf,
    callback = should_close_editor,
  })

  -- Enter insert mode
  vim.cmd("startinsert")
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

    local existing_content = utils.load_program(current_state.current_file)

    if existing_content ~= "" then
      local choice = vim.fn.confirm(string.format("Replace existing %s content?", current_state.current_file), "&Yes\n&No", 2)

      if choice == 1 then
        content = selection
      else
        content = existing_content
      end
    else
      content = selection
    end
  else
    content = utils.load_program(current_state.current_file)
  end

  state.set("current_program", content)
  create_program_window(content)
end

return M
