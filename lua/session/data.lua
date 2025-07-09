local config = require("session.config")
local tracking = require("session.tracking")

local M = {}

-- Keep track of last loaded data for directory switching
local last_loaded_data = nil

-- Data collectors
local function collect_marks()
  local marks = {}
  
  -- Save global marks A-Z
  for i = 65, 90 do -- ASCII A-Z
    local mark = string.char(i)
    local pos = vim.fn.getpos("'" .. mark)
    
    if pos[2] > 0 then -- Valid mark (line number > 0)
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
  
  return marks
end

local function clean_register_content(content)
  -- Remove or replace problematic characters that can't be JSON encoded
  -- These are typically special key codes from recorded macros
  
  -- Replace common escape sequences with readable text
  content = content:gsub("\27", "<Esc>")      -- Escape key
  content = content:gsub("\r", "<CR>")        -- Carriage return
  content = content:gsub("\n", "<NL>")        -- Newline
  content = content:gsub("\t", "<Tab>")       -- Tab
  content = content:gsub("\b", "<BS>")        -- Backspace
  content = content:gsub("\f", "<FF>")        -- Form feed
  content = content:gsub("\v", "<VT>")        -- Vertical tab
  content = content:gsub("\a", "<Bell>")      -- Bell
  content = content:gsub("\0", "<Null>")      -- Null character
  
  -- Handle special Vim key sequences
  content = content:gsub("<80>[^>]*>", "")    -- Special key sequences like <80><fd>5
  content = content:gsub("<[A-Za-z0-9_%-]+>", function(match)
    -- Keep known safe key names, remove unknown ones
    local safe_keys = {
      "<Space>", "<Tab>", "<CR>", "<NL>", "<Esc>", "<BS>", "<Del>", "<Insert>",
      "<Home>", "<End>", "<PageUp>", "<PageDown>", "<Up>", "<Down>", "<Left>", "<Right>",
      "<F1>", "<F2>", "<F3>", "<F4>", "<F5>", "<F6>", "<F7>", "<F8>", "<F9>", "<F10>", "<F11>", "<F12>",
      "<C-a>", "<C-b>", "<C-c>", "<C-d>", "<C-e>", "<C-f>", "<C-g>", "<C-h>", "<C-i>", "<C-j>", "<C-k>", "<C-l>", "<C-m>", "<C-n>", "<C-o>", "<C-p>", "<C-q>", "<C-r>", "<C-s>", "<C-t>", "<C-u>", "<C-v>", "<C-w>", "<C-x>", "<C-y>", "<C-z>",
      "<M-a>", "<M-b>", "<M-c>", "<M-d>", "<M-e>", "<M-f>", "<M-g>", "<M-h>", "<M-i>", "<M-j>", "<M-k>", "<M-l>", "<M-m>", "<M-n>", "<M-o>", "<M-p>", "<M-q>", "<M-r>", "<M-s>", "<M-t>", "<M-u>", "<M-v>", "<M-w>", "<M-x>", "<M-y>", "<M-z>",
      "<S-Tab>", "<Leader>", "<LocalLeader>"
    }
    
    local lower_match = match:lower()
    for _, safe_key in ipairs(safe_keys) do
      if lower_match == safe_key:lower() then
        return match  -- Keep safe keys
      end
    end
    return ""  -- Remove unknown key sequences
  end)
  
  -- Remove control characters by iterating through each byte
  local cleaned = ""
  for i = 1, #content do
    local byte = content:byte(i)
    if byte and byte >= 32 and byte <= 126 then
      -- Keep printable ASCII (32-126)
      cleaned = cleaned .. content:sub(i, i)
    elseif byte and byte >= 160 and byte <= 255 then
      -- Keep printable extended ASCII (160-255)
      cleaned = cleaned .. content:sub(i, i)
    end
    -- Skip everything else (control characters, etc.)
  end
  content = cleaned
  
  -- Remove multiple consecutive spaces/newlines that might be artifacts
  content = content:gsub("  +", " ")         -- Multiple spaces to single space
  content = content:gsub("<NL><NL>+", "<NL>") -- Multiple newlines to single
  
  -- Trim whitespace
  content = content:gsub("^%s+", ""):gsub("%s+$", "")
  
  return content
end

local function collect_registers()
  local registers = {}
  
  for _, reg in ipairs(config.registers_to_save) do
    local content = vim.fn.getreg(reg)
    local regtype = vim.fn.getregtype(reg)
    
    -- Only save if content is non-empty and serializable
    if content ~= "" and type(content) == "string" and type(regtype) == "string" then
      -- Clean the content to remove problematic characters
      local cleaned_content = clean_register_content(content)
      
      -- Skip if content becomes empty after cleaning
      if cleaned_content == "" then
        goto continue
      end
      
      local test_data = {
        content = cleaned_content,
        type = regtype,
      }
      
      -- Test if this specific register data can be JSON encoded
      local ok, err = pcall(vim.fn.json_encode, test_data)
      if ok then
        registers[reg] = test_data
      else
        -- Still failing after cleaning - try super aggressive cleaning
        local super_cleaned = cleaned_content:gsub("[^%w%s%p]", ""):gsub("%p", "")
        if super_cleaned ~= "" then
          local super_test_data = {
            content = super_cleaned,
            type = regtype,
          }
          local super_ok, _ = pcall(vim.fn.json_encode, super_test_data)
          if super_ok then
            registers[reg] = super_test_data
          end
        end
      end
      
      ::continue::
    end
  end
  
  return registers
end

local function collect_search_history()
  local history = {}
  local count = vim.fn.histnr('search')
  
  for i = math.max(1, count - config.HISTORY_LIMIT + 1), count do
    local item = vim.fn.histget('search', i)
    if item ~= "" then
      table.insert(history, item)
    end
  end
  
  return history
end

local function collect_command_history()
  local history = {}
  local count = vim.fn.histnr('cmd')
  
  for i = math.max(1, count - config.HISTORY_LIMIT + 1), count do
    local item = vim.fn.histget('cmd', i)
    if item ~= "" then
      table.insert(history, item)
    end
  end
  
  return history
end

local function collect_quickfix_data()
  local qf_data = {
    quickfix = nil,
    location_lists = {}
  }
  
  -- Get quickfix list
  local qf_list = vim.fn.getqflist({ all = 1 })
  if #qf_list.items > 0 then
    -- Filter quickfix items to only include serializable data
    local filtered_items = {}
    for _, item in ipairs(qf_list.items) do
      table.insert(filtered_items, {
        bufnr = item.bufnr,
        lnum = item.lnum,
        col = item.col,
        text = item.text or "",
        type = item.type or "",
        valid = item.valid or 0,
        filename = item.filename or "",
      })
    end
    
    qf_data.quickfix = {
      items = filtered_items,
      title = qf_list.title or "",
      idx = qf_list.idx or 1,
    }
  end
  
  -- Get location lists for all windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local loc_list = vim.fn.getloclist(win, { all = 1 })
    if #loc_list.items > 0 then
      -- Filter location list items similarly
      local filtered_items = {}
      for _, item in ipairs(loc_list.items) do
        table.insert(filtered_items, {
          bufnr = item.bufnr,
          lnum = item.lnum,
          col = item.col,
          text = item.text or "",
          type = item.type or "",
          valid = item.valid or 0,
          filename = item.filename or "",
        })
      end
      
      qf_data.location_lists["win_" .. win] = {
        items = filtered_items,
        title = loc_list.title or "",
        idx = loc_list.idx or 1,
      }
    end
  end
  
  return qf_data
end

-- Data restorers
local function restore_marks(marks)
  if not marks then return end
  
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

local function restore_registers(registers)
  if not registers then return end
  
  for reg, data in pairs(registers) do
    if config.registers_to_save and vim.tbl_contains(config.registers_to_save, reg) then
      vim.fn.setreg(reg, data.content, data.type)
    end
  end
end

local function restore_search_history(history)
  if not history then return end
  
  -- Clear existing search history
  vim.fn.histdel('search')
  
  -- Restore search history
  for _, item in ipairs(history) do
    vim.fn.histadd('search', item)
  end
end

local function restore_command_history(history)
  if not history then return end
  
  -- Note: We don't clear command history as it might contain important commands
  -- Just add our saved commands
  for _, item in ipairs(history) do
    vim.fn.histadd('cmd', item)
  end
end

local function restore_quickfix_data(qf_data)
  if not qf_data then return end
  
  -- Restore quickfix list
  if qf_data.quickfix then
    vim.fn.setqflist(qf_data.quickfix.items, 'r')
    if qf_data.quickfix.title then
      vim.fn.setqflist({}, 'a', { title = qf_data.quickfix.title })
    end
    if qf_data.quickfix.idx then
      vim.fn.setqflist({}, 'a', { idx = qf_data.quickfix.idx })
    end
  end
  
  -- Restore location lists
  for win_key, loc_data in pairs(qf_data.location_lists or {}) do
    local win_id = tonumber(win_key:match("win_(%d+)"))
    if win_id and vim.api.nvim_win_is_valid(win_id) then
      vim.fn.setloclist(win_id, loc_data.items, 'r')
      if loc_data.title then
        vim.fn.setloclist(win_id, {}, 'a', { title = loc_data.title })
      end
      if loc_data.idx then
        vim.fn.setloclist(win_id, {}, 'a', { idx = loc_data.idx })
      end
    end
  end
end

-- Main functions
function M.save_session_data()
  local data = {
    version = config.DATA_VERSION,
    original_cwd = vim.fn.getcwd(),  -- Use current directory (locked at session start)
    marks = collect_marks(),
    last_accessed_buffers = tracking.get_access_history(),
    registers = collect_registers(),
    search_history = collect_search_history(),
    command_history = collect_command_history(),
  }
  
  -- Collect quickfix data
  local qf_data = collect_quickfix_data()
  if qf_data.quickfix then
    data.quickfix = qf_data.quickfix
  end
  if next(qf_data.location_lists) then
    data.location_lists = qf_data.location_lists
  end
  
  local data_file = config.get_data_file()
  
  -- Try to encode with better error handling
  local ok, encoded = pcall(vim.fn.json_encode, data)
  if not ok then
    -- Find which part is causing the problem
    local test_parts = {
      version = data.version,
      original_cwd = data.original_cwd,
      marks = data.marks,
      last_accessed_buffers = data.last_accessed_buffers,
      registers = data.registers,
      search_history = data.search_history,
      command_history = data.command_history,
      quickfix = data.quickfix,
      location_lists = data.location_lists,
    }
    
    for part_name, part_data in pairs(test_parts) do
      if part_data then
        local part_ok, _ = pcall(vim.fn.json_encode, part_data)
        if not part_ok then
          vim.notify("Session data encoding failed in: " .. part_name, vim.log.levels.ERROR)
          -- Try to save without the problematic part
          data[part_name] = nil
        end
      end
    end
    
    -- Try encoding again without problematic parts
    ok, encoded = pcall(vim.fn.json_encode, data)
    if not ok then
      vim.notify("Failed to encode session data completely", vim.log.levels.ERROR)
      return false
    end
  end
  
  local file = io.open(data_file, "w")
  if not file then
    return false
  end
  
  file:write(encoded)
  file:close()
  
  return true
end

function M.load_session_data()
  local data_file = config.get_data_file()
  local data = nil
  
  -- Try to load data file
  if vim.fn.filereadable(data_file) == 1 then
    local file = io.open(data_file, "r")
    if file then
      local content = file:read("*a")
      file:close()
      
      local ok, decoded = pcall(vim.fn.json_decode, content)
      if ok and decoded then
        -- Validate version
        if not decoded.version or decoded.version ~= config.DATA_VERSION then
          return false
        end
        data = decoded
      else
        return false
      end
    end
  end
  
  if not data then
    return false
  end
  
  -- Store loaded data for directory switching
  last_loaded_data = data
  
  -- Restore data
  restore_marks(data.marks)
  restore_registers(data.registers)
  restore_search_history(data.search_history)
  restore_command_history(data.command_history)
  
  -- Restore quickfix data
  local qf_data = {}
  if data.quickfix then
    qf_data.quickfix = data.quickfix
  end
  if data.location_lists then
    qf_data.location_lists = data.location_lists
  end
  restore_quickfix_data(qf_data)
  
  -- Update tracking with restored buffer list
  if data.last_accessed_buffers then
    tracking.clear_access_history()
    for i = #data.last_accessed_buffers, 1, -1 do
      local bufname = data.last_accessed_buffers[i]
      if vim.fn.filereadable(bufname) == 1 then
        tracking.track_buffer_access(bufname)
      end
    end
  end
  
  return true
end

function M.get_last_loaded_data()
  return last_loaded_data
end

return M
