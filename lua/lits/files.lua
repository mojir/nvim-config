-- lua/lits/files.lua
local config = require("lits.config")
local state = require("lits.state")
local utils = require("lits.utils")
local ui = require("lits.ui")

local M = {}

function M.file_exists(filename)
  local filepath = utils.get_program_path(filename)
  return vim.fn.filereadable(filepath) == 1
end

function M.list_files()
  local programs_dir = config.get().programs_dir
  if not utils.ensure_programs_dir() then
    return {}
  end
  
  local files = {}
  
  -- Use Vim's glob function instead of external find command
  local pattern = programs_dir .. "*.lits"
  local found_files = vim.fn.glob(pattern, false, true)
  
  for _, filepath in ipairs(found_files) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    table.insert(files, filename)
  end
  
  return files
end

function M.delete_program(filename)
  local filepath = utils.get_program_path(filename)
  if vim.fn.filereadable(filepath) == 1 then
    local ok = pcall(vim.fn.delete, filepath)
    return ok
  end
  return false
end

function M.get_starting_file()
  local current_state = state.get()
  local last_file = current_state.last_explicit_file
  
  -- If we have a last explicit file and it exists, use it
  if last_file and last_file ~= config.get().default_file and M.file_exists(last_file) then
    return last_file
  end
  
  -- Otherwise use default
  return config.get().default_file
end

function M.save_as_dialog()
  local current_state = state.get()
  local current_name = current_state.current_file
  local default_name = ""
  
  -- Suggest the full name with .lits extension
  if current_name == config.get().default_file then
    default_name = ""
  else
    default_name = current_name -- Keep full filename including .lits
  end
  
  local filename = vim.fn.input("Save as: ", default_name)
  if filename == "" or filename:match("^%s*$") then
    print("Save cancelled")
    return false
  end
  
  -- Check for invalid extensions
  local has_extension = filename:match("%.%w+$")
  if has_extension then
    local extension = filename:match("%.(%w+)$")
    if extension ~= "lits" then
      print("Error: Only .lits files are supported (got ." .. extension .. ")")
      return false
    end
  else
    -- No extension provided, add .lits
    filename = filename .. ".lits"
  end
  
  -- Validate filename
  if filename == config.get().default_file then
    print("Cannot save as " .. config.get().default_file .. " (reserved for scratch)")
    return false
  end
  
  -- Get current content
  if not (current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf)) then
    print("No content to save")
    return false
  end
  
  local lines = vim.api.nvim_buf_get_lines(current_state.editor_buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Save to new file
  if not utils.save_program(content, filename) then
    print("Failed to save file")
    return false
  end
  
  -- Handle the move logic: if coming from DEFAULT.lits, clear it
  local was_default = (current_name == config.get().default_file)
  if was_default then
    M.delete_program(config.get().default_file)
  end
  
  -- Update state
  state.set("current_file", filename)
  state.set("current_program", content)
  state.set("last_explicit_file", filename)
  
  -- Update window title if editor is open
  local editor_win = current_state.editor_win
  if editor_win and vim.api.nvim_win_is_valid(editor_win) then
    vim.api.nvim_win_set_config(editor_win, {
      title = string.format(" Lits Editor (%s) ", filename)
    })
  end
  
  if was_default then
    print("Saved as: " .. filename .. " (scratch cleared)")
  else
    print("Saved as: " .. filename)
  end
  
  return true
end

function M.open_file_picker()
  -- If called from within Lits editor, temporarily close it
  local current_state = state.get()
  local was_in_editor = current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win)
  local original_win = current_state.original_win
  
  if was_in_editor then
    -- Save current content before temporarily closing
    if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
      local lines = vim.api.nvim_buf_get_lines(current_state.editor_buf, 0, -1, false)
      local content = table.concat(lines, "\n")
      utils.save_program(content, current_state.current_file)
      state.set("current_program", content)
    end
    
    -- Temporarily close editor and return to original window
    ui.close_editor()
    if original_win and vim.api.nvim_win_is_valid(original_win) then
      vim.api.nvim_set_current_win(original_win)
    end
  end
  
  local files = M.list_files()
  
  if #files == 0 then
    print("No Lits files found in " .. config.get().programs_dir)
    -- If we closed the editor, reopen it
    if was_in_editor then
      vim.defer_fn(function()
        require("lits.editor").open(false)
      end, 100)
    end
    return
  end
  
  -- Check if telescope is available
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    print("Telescope not available")
    if was_in_editor then
      vim.defer_fn(function()
        require("lits.editor").open(false)
      end, 100)
    end
    return
  end
  
  -- Use Telescope to pick file
  require("telescope.pickers").new({}, {
    prompt_title = "Lits Programs",
    finder = require("telescope.finders").new_table({
      results = files,
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- Use default select action
      require("telescope.actions").select_default:replace(function()
        local selection = require("telescope.actions.state").get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        
        if selection then
          M.load_file(selection.value)
          -- Reopen editor with the loaded file
          if was_in_editor then
            vim.defer_fn(function()
              require("lits.editor").open(false)
            end, 100)
          end
        else
          -- User cancelled, reopen editor if it was open
          if was_in_editor then
            vim.defer_fn(function()
              require("lits.editor").open(false)
            end, 100)
          end
        end
      end)
      
      -- Handle escape/cancel
      map("i", "<Esc>", function()
        require("telescope.actions").close(prompt_bufnr)
        if was_in_editor then
          vim.defer_fn(function()
            require("lits.editor").open(false)
          end, 100)
        end
      end)
      
      return true
    end,
  }):find()
end

function M.load_file(filename)
  if not M.file_exists(filename) then
    print("File not found: " .. filename)
    return false
  end
  
  local content = utils.load_program(filename)
  local current_state = state.get()
  
  -- Update state
  state.set("current_file", filename)
  state.set("current_program", content)
  
  -- If it's not the default file, remember it as explicit
  if filename ~= config.get().default_file then
    state.set("last_explicit_file", filename)
  end
  
  -- If editor is open, update it
  if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
    local lines = vim.split(content, "\n")
    vim.api.nvim_buf_set_lines(current_state.editor_buf, 0, -1, false, lines)
    
    -- Update window title
    if current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win) then
      vim.api.nvim_win_set_config(current_state.editor_win, {
        title = string.format(" Lits Editor (%s) ", filename)
      })
    end
  end
  
  print("Loaded: " .. filename)
  return true
end

function M.delete_current_file()
  local current_state = state.get()
  local current_file = current_state.current_file
  
  if current_file == config.get().default_file then
    print("Cannot delete scratch file")
    return false
  end
  
  local choice = vim.fn.confirm(
    "Delete " .. current_file .. "?",
    "&Delete\n&Cancel",
    2
  )
  
  if choice ~= 1 then
    print("Delete cancelled")
    return false
  end
  
  if M.delete_program(current_file) then
    print("Deleted: " .. current_file)
    
    -- Switch back to default file
    state.set("current_file", config.get().default_file)
    state.set("current_program", "")
    state.set("last_explicit_file", nil)
    
    -- Update editor if open
    if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
      vim.api.nvim_buf_set_lines(current_state.editor_buf, 0, -1, false, {""})
      
      if current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win) then
        vim.api.nvim_win_set_config(current_state.editor_win, {
          title = string.format(" Lits Editor (%s) ", config.get().default_file)
        })
      end
    end
    
    return true
  else
    print("Failed to delete file")
    return false
  end
end

function M.new_file_dialog()
  local filename = vim.fn.input("New file name: ")
  if filename == "" or filename:match("^%s*$") then
    print("New file cancelled")
    return false
  end
  
  -- Check for invalid extensions
  local has_extension = filename:match("%.%w+$")
  if has_extension then
    local extension = filename:match("%.(%w+)$")
    if extension ~= "lits" then
      print("Error: Only .lits files are supported (got ." .. extension .. ")")
      return false
    end
  else
    -- No extension provided, add .lits
    filename = filename .. ".lits"
  end
  
  -- Validate filename
  if filename == config.get().default_file then
    print("Cannot create file named " .. config.get().default_file .. " (reserved)")
    return false
  end
  
  if M.file_exists(filename) then
    local choice = vim.fn.confirm(
      filename .. " already exists. Open it?",
      "&Open\n&Cancel",
      2
    )
    
    if choice == 1 then
      return M.load_file(filename)
    else
      return false
    end
  end
  
  -- Create new file with empty content
  if utils.save_program("", filename) then
    state.set("current_file", filename)
    state.set("current_program", "")
    state.set("last_explicit_file", filename)
    
    -- Update editor if open
    local current_state = state.get()
    if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
      vim.api.nvim_buf_set_lines(current_state.editor_buf, 0, -1, false, {""})
      
      if current_state.editor_win and vim.api.nvim_win_is_valid(current_state.editor_win) then
        vim.api.nvim_win_set_config(current_state.editor_win, {
          title = string.format(" Lits Editor (%s) ", filename)
        })
      end
    end
    
    print("Created: " .. filename)
    return true
  else
    print("Failed to create file")
    return false
  end
end

return M
