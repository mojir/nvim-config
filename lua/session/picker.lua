local config = require("session.config")
local core = require("session.core")
local tracking = require("session.tracking")

local M = {}

-- Helper function to format session name back to readable path
local function format_session_name(session_name)
  -- Convert underscores back to path separators
  local path = session_name:gsub("_", "/")
  
  -- Add leading slash if it doesn't start with one
  if not path:match("^/") then
    path = "/" .. path
  end
  
  -- Replace home directory with ~
  local home = vim.fn.expand("~")
  if path:sub(1, #home) == home then
    path = "~" .. path:sub(#home + 1)
  end
  
  return path
end

-- Helper function to get git branch for session
local function get_session_git_branch(session_name)
  -- Convert session name back to path
  local path = session_name:gsub("_", "/")
  if not path:match("^/") then
    path = "/" .. path
  end
  
  -- Replace ~ with home directory
  local home = vim.fn.expand("~")
  if path:sub(1, 2) == "~/" then
    path = home .. path:sub(2)
  elseif path == "~" then
    path = home
  end
  
  -- Check if directory exists and has git
  if vim.fn.isdirectory(path) == 0 or vim.fn.isdirectory(path .. "/.git") == 0 then
    return nil
  end
  
  -- Get git branch
  local handle = io.popen("cd " .. vim.fn.shellescape(path) .. " && git branch --show-current 2>/dev/null")
  if handle then
    local branch = handle:read("*l")
    handle:close()
    return branch and branch ~= "" and branch or nil
  end
  
  return nil
end

-- Helper function to get buffer count from session file
local function get_session_buffer_count(session_name)
  local session_file = config.session_dir .. session_name .. "/session.vim"
  
  if vim.fn.filereadable(session_file) == 0 then
    return 0
  end
  
  local count = 0
  local file = io.open(session_file, "r")
  if file then
    for line in file:lines() do
      -- Count buffer-related lines more broadly
      if line:match("^edit ") or line:match("^badd ") then
        -- Skip special buffers
        if not line:match("NERD_tree") and not line:match("__Tagbar__") and not line:match("^[%s]*$") then
          count = count + 1
        end
      end
    end
    file:close()
  end
  
  return count
end

-- Helper function to format relative time
local function format_relative_time(timestamp)
  if not timestamp or timestamp == 0 then
    return "unknown"
  end
  
  local now = os.time()
  local diff = now - timestamp
  
  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local minutes = math.floor(diff / 60)
    return minutes .. "m ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. "h ago"
  elseif diff < 604800 then
    local days = math.floor(diff / 86400)
    return days .. "d ago"
  else
    -- Fall back to absolute date for older items
    return os.date("%Y-%m-%d", timestamp)
  end
end

function M.session_picker()
  local session_items = core.get_sorted_sessions_with_display()
  
  if #session_items == 0 then
    print("No sessions found")
    return
  end
  
  local ok = pcall(require, "telescope")
  if not ok then
    core.list_sessions()
    return
  end
  
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  
  -- Add relative time, buffer count, and git branch to session items
  local enhanced_session_items = {}
  local session_info = {}
  
  -- First pass: collect all the info and find max widths
  for _, session in ipairs(session_items) do
    local formatted_path = format_session_name(session.name)
    local relative_time = format_relative_time(session.timestamp)
    local buffer_count = get_session_buffer_count(session.name)
    local git_branch = get_session_git_branch(session.name)
    
    -- Add marker for current session
    local marker = session.is_current and "* " or "  "
    local base_display = marker .. formatted_path
    
    -- Build the info part (buffer count)
    local buffer_text = buffer_count == 1 and "1 buffer" or buffer_count .. " buffers"
    local buffer_part = "(" .. buffer_text .. ")"
    
    table.insert(session_info, {
      session = session,
      base_display = base_display,
      buffer_part = buffer_part,
      relative_time = relative_time,
      git_branch = git_branch,
      timestamp = session.timestamp,
    })
  end
  
  -- Calculate max widths for both columns
  local max_path_width = 0
  local max_buffer_width = 0
  
  for _, info in ipairs(session_info) do
    max_path_width = math.max(max_path_width, vim.fn.strdisplaywidth(info.base_display))
    max_buffer_width = math.max(max_buffer_width, vim.fn.strdisplaywidth(info.buffer_part))
  end
  
  -- Second pass: build aligned display strings
  for _, info in ipairs(session_info) do
    local path_padding = max_path_width - vim.fn.strdisplaywidth(info.base_display)
    local buffer_padding = max_buffer_width - vim.fn.strdisplaywidth(info.buffer_part)
    
    local display = info.base_display .. 
                   string.rep(" ", path_padding) .. 
                   "  " .. info.buffer_part .. 
                   string.rep(" ", buffer_padding) .. 
                   "  " .. info.relative_time
    
    -- Add git branch as last column (no alignment needed)
    if info.git_branch then
      display = display .. "  " .. info.git_branch
    end
    
    table.insert(enhanced_session_items, {
      name = info.session.name,
      display = display,
      dir = info.session.dir,
      timestamp = info.session.timestamp,
    })
  end
  
  require("telescope.pickers")
    .new({}, {
      prompt_title = "Sessions (sorted by last used) - <C-d> to delete, <Tab> to select",
      finder = require("telescope.finders").new_table({
        results = enhanced_session_items,
        entry_maker = function(entry)
          return {
            value = entry.name,
            display = entry.display,
            ordinal = entry.name,
            path = entry.dir,
          }
        end,
      }),
      sorter = require("telescope.config").values.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- Default action (Enter) - switch to session
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          
          if selection then
            core.switch_to_session(selection.value)
          end
        end)
        
        -- Delete action - handles both single and multi-selection
        local delete_action = function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local multi_selections = picker:get_multi_selection()
          
          local sessions_to_delete = {}
          
          if #multi_selections > 0 then
            -- Multi-selection: delete all selected sessions
            for _, selection in ipairs(multi_selections) do
              table.insert(sessions_to_delete, selection.value)
            end
          else
            -- Single selection: delete current session
            local selection = action_state.get_selected_entry()
            if selection then
              table.insert(sessions_to_delete, selection.value)
            end
          end
          
          if #sessions_to_delete == 0 then
            return
          end
          
          local current_session = config.get_session_name()
          local deleted_count = 0
          local deleted_current = false
          
          -- Delete all selected sessions
          for _, session_name in ipairs(sessions_to_delete) do
            local session_path = config.session_dir .. session_name .. "/"
            local delete_success = pcall(vim.fn.delete, session_path, "rf")
            
            if delete_success then
              deleted_count = deleted_count + 1
              if session_name == current_session then
                deleted_current = true
              end
            end
          end
          
          -- Clear marks and tracking if current session was deleted
          if deleted_current then
            for i = 65, 90 do
              local mark = string.char(i)
              vim.cmd("silent! delmarks " .. mark)
            end
            tracking.clear_access_history()
          end
          
          -- Refresh the picker in-place without closing
          local new_session_items = core.get_sorted_sessions_with_display()
          local new_enhanced_items = {}
          local new_session_info = {}
          
          -- First pass: collect info and find max widths
          for _, session in ipairs(new_session_items) do
            local formatted_path = format_session_name(session.name)
            local relative_time = format_relative_time(session.timestamp)
            local buffer_count = get_session_buffer_count(session.name)
            local git_branch = get_session_git_branch(session.name)
            
            local marker = session.is_current and "* " or "  "
            local base_display = marker .. formatted_path
            local buffer_text = buffer_count == 1 and "1 buffer" or buffer_count .. " buffers"
            local buffer_part = "(" .. buffer_text .. ")"
            
            table.insert(new_session_info, {
              session = session,
              base_display = base_display,
              buffer_part = buffer_part,
              relative_time = relative_time,
              git_branch = git_branch,
              timestamp = session.timestamp,
            })
          end
          
          -- Calculate max widths for both columns
          max_path_width = 0
          max_buffer_width = 0
          
          for _, info in ipairs(new_session_info) do
            max_path_width = math.max(max_path_width, vim.fn.strdisplaywidth(info.base_display))
            max_buffer_width = math.max(max_buffer_width, vim.fn.strdisplaywidth(info.buffer_part))
          end
          
          -- Second pass: build aligned display strings
          for _, info in ipairs(new_session_info) do
            local path_padding = max_path_width - vim.fn.strdisplaywidth(info.base_display)
            local buffer_padding = max_buffer_width - vim.fn.strdisplaywidth(info.buffer_part)
            
            local display = info.base_display .. 
                           string.rep(" ", path_padding) .. 
                           "  " .. info.buffer_part .. 
                           string.rep(" ", buffer_padding) .. 
                           "  " .. info.relative_time
            
            -- Add git branch as last column (no alignment needed)
            if info.git_branch then
              display = display .. "  " .. info.git_branch
            end
            
            table.insert(new_enhanced_items, {
              name = info.session.name,
              display = display,
              dir = info.session.dir,
              timestamp = info.session.timestamp,
            })
          end
          
          local new_finder = require("telescope.finders").new_table({
            results = new_enhanced_items,
            entry_maker = function(entry)
              return {
                value = entry.name,
                display = entry.display,
                ordinal = entry.name,
                path = entry.dir,
              }
            end,
          })
          
          picker:refresh(new_finder, { reset_prompt = true })
        end
        
        -- Map delete action to <C-d>
        map("i", "<C-d>", delete_action)
        map("n", "<C-d>", delete_action)
        
        -- Enable multi-selection with Tab/Shift-Tab
        map("i", "<Tab>", actions.toggle_selection + actions.move_selection_next)
        map("i", "<S-Tab>", actions.toggle_selection + actions.move_selection_previous)
        map("n", "<Tab>", actions.toggle_selection + actions.move_selection_next)
        map("n", "<S-Tab>", actions.toggle_selection + actions.move_selection_previous)
        
        return true
      end,
    })
    :find()
end

return M
