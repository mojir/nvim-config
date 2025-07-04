local config = require("lits.config")
local state = require("lits.state")

local M = {}

function M.ensure_programs_dir()
  local ok, err = pcall(vim.fn.mkdir, config.get().programs_dir, "p")
  if not ok then
    vim.notify("Failed to create lits programs directory: " .. err, vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.get_program_path(filename)
  filename = filename or state.get().current_file
  return config.get().programs_dir .. filename
end

function M.load_program(filename)
  filename = filename or state.get().current_file
  local filepath = M.get_program_path(filename)

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

function M.save_program(content, filename)
  filename = filename or state.get().current_file

  if not M.ensure_programs_dir() then
    return false
  end

  local filepath = M.get_program_path(filename)

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

function M.delete_program(filename)
  local filepath = M.get_program_path(filename)
  if vim.fn.filereadable(filepath) == 1 then
    local ok = pcall(vim.fn.delete, filepath)
    if ok then
      -- Clean up empty directories after deletion
      M.cleanup_empty_directories(filepath)
    end
    return ok
  end
  return false
end

function M.file_exists(filename)
  local filepath = M.get_program_path(filename)
  return vim.fn.filereadable(filepath) == 1
end

function M.get_visual_selection()
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
    return table.concat(lines, "\n")
  elseif mode == "\22" then
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
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    else
      lines[1] = string.sub(lines[1], start_pos[3])
      lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
    return table.concat(lines, "\n")
  end
end

function M.calculate_window_size(content)
  local lines = vim.split(content or "", "\n")
  local cfg = config.get()

  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    return cfg.popup.min_width, cfg.popup.min_height
  end

  local max_line_width = math.floor(vim.o.columns * cfg.popup.max_line_width_ratio)
  local content_width = 0

  for _, line in ipairs(lines) do
    local line_width = math.min(vim.fn.strdisplaywidth(line), max_line_width)
    content_width = math.max(content_width, line_width)
  end

  local content_height = #lines
  local max_width = math.floor(vim.o.columns * cfg.popup.max_width_ratio)
  local max_height = math.floor(vim.o.lines * cfg.popup.max_height_ratio)

  local width = math.max(cfg.popup.min_width, math.min(content_width + 4, max_width))
  local height = math.max(cfg.popup.min_height, math.min(content_height + 2, max_height))

  return width, height
end

function M.validate_filepath(filepath)
  local programs_dir = vim.fn.resolve(config.get().programs_dir)
  local resolved_path = vim.fn.resolve(filepath)
  return resolved_path:sub(1, #programs_dir) == programs_dir
end

function M.evaluate_lits()
  -- Check if lits command exists
  local handle = io.popen("command -v lits >/dev/null 2>&1 && echo 'exists'")
  local lits_exists = handle and handle:read("*a"):match("exists")
  if handle then
    handle:close()
  end

  if not lits_exists then
    return false, "lits command not found. Please ensure lits is installed and in PATH."
  end

  local current_state = state.get()
  local filepath = M.get_program_path(current_state.current_file)

  if not M.validate_filepath(filepath) then
    return false, "Invalid file path for security reasons."
  end

  -- Save current content before evaluation
  if current_state.editor_buf and vim.api.nvim_buf_is_valid(current_state.editor_buf) then
    local lines = vim.api.nvim_buf_get_lines(current_state.editor_buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    if not M.save_program(content, current_state.current_file) then
      return false, "Failed to save program before evaluation."
    end
  end

  local cmd = string.format("NO_COLOR=1 lits -f %s 2>&1", vim.fn.shellescape(filepath))
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code == 0 then
    result = result:gsub("\n$", "")
    state.set("last_result", result)
    return true, result
  else
    return false, string.format("Lits evaluation failed (exit code %d):\n%s", exit_code, result)
  end
end

function M.normalize_path(path)
  -- Resolve relative paths and normalize
  return vim.fn.resolve(vim.fn.fnamemodify(path, ":p"))
end

function M.is_safe_path(filename)
  local programs_dir = vim.fn.resolve(config.get().programs_dir)
  local full_path = M.normalize_path(M.get_program_path(filename))
  
  -- Check if the resolved path is within the programs directory
  return full_path:sub(1, #programs_dir) == programs_dir
end

function M.ensure_directory_for_file(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    local ok, err = pcall(vim.fn.mkdir, dir, "p")
    if not ok then
      vim.notify("Failed to create directory: " .. err, vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

function M.cleanup_empty_directories(filepath)
  local programs_dir = vim.fn.resolve(config.get().programs_dir)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  
  -- Normalize paths for comparison
  programs_dir = vim.fn.fnamemodify(programs_dir, ":p"):gsub("/$", "")
  
  while true do
    -- Normalize current directory path
    local normalized_dir = vim.fn.fnamemodify(dir, ":p"):gsub("/$", "")
    
    -- Stop if we've reached the programs directory
    if normalized_dir == programs_dir then
      break
    end
    
    -- Check if directory is empty
    local files = vim.fn.glob(dir .. "/*", false, true)
    local hidden_files = vim.fn.glob(dir .. "/.*", false, true)
    
    -- Filter out . and .. from hidden files
    hidden_files = vim.tbl_filter(function(f)
      local basename = vim.fn.fnamemodify(f, ":t")
      return basename ~= "." and basename ~= ".."
    end, hidden_files)
    
    if #files == 0 and #hidden_files == 0 then
      local success = pcall(vim.fn.delete, dir, "d")
      if not success then
        break -- Can't delete, stop trying
      end
      -- Move to parent directory
      dir = vim.fn.fnamemodify(dir, ":h")
    else
      break -- Directory not empty, stop
    end
  end
end

-- Update the save_program function
function M.save_program(content, filename)
  filename = filename or state.get().current_file

  -- Validate path safety
  if not M.is_safe_path(filename) then
    vim.notify("Invalid file path: cannot save outside programs directory", vim.log.levels.ERROR)
    return false
  end

  if not M.ensure_programs_dir() then
    return false
  end

  local filepath = M.get_program_path(filename)
  
  -- Ensure directory exists for the file
  if not M.ensure_directory_for_file(filepath) then
    return false
  end

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

return M
