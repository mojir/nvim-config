local M = {}

-- Path to your phrases file
local phrases_file = vim.fn.expand("~/.config/nvim/data/my_snippets.json")

-- Function to expand placeholders
local function expand_placeholders(text)
  local result = text

  -- Get current file information
  local current_file = vim.api.nvim_buf_get_name(0)

  -- Date placeholders
  result = result:gsub("{date:day}", os.date("%A")) -- Monday, Tuesday, etc
  result = result:gsub("{date:date}", os.date("%Y-%m-%d")) -- 2025-01-02
  result = result:gsub("{date:time}", os.date("%H:%M")) -- 14:38
  result = result:gsub("{date:week}", os.date("%V")) -- ISO week number
  result = result:gsub("{cwd}", vim.fn.getcwd())

  -- File placeholders
  if current_file and current_file ~= "" then
    -- Just filename: foo.txt
    local filename = vim.fn.fnamemodify(current_file, ":t")
    result = result:gsub("{file:name}", filename)

    -- Relative path from cwd: src/foo.txt
    local relative_path = vim.fn.fnamemodify(current_file, ":.")
    result = result:gsub("{file:rel}", relative_path)

    -- Absolute path: /Users/joe/proj/src/foo.txt
    result = result:gsub("{file:abs}", current_file)
  else
    -- Handle case when no file is open
    result = result:gsub("{file:name}", "[no file]")
    result = result:gsub("{file:rel}", "[no file]")
    result = result:gsub("{file:abs}", "[no file]")
  end

  return result
end

-- Function to read phrases from JSON file (now expects array of pairs)
local function read_phrases()
  local phrases = {}
  local file = io.open(phrases_file, "r")

  if not file then
    vim.notify("Phrases file not found: " .. phrases_file, vim.log.levels.WARN)
    return phrases
  end

  local content = file:read("*all")
  file:close()

  -- Parse JSON
  local ok, json_data = pcall(vim.fn.json_decode, content)
  if not ok then
    vim.notify("Invalid JSON in phrases file: " .. phrases_file, vim.log.levels.ERROR)
    return phrases
  end

  -- Convert JSON array of pairs to phrases array (preserves order)
  for i, pair in ipairs(json_data) do
    if type(pair) == "table" and #pair >= 2 then
      local description = pair[1]
      local phrase = pair[2]
      table.insert(phrases, {
        index = i,
        description = description,
        original = phrase,
        expanded = expand_placeholders(phrase),
        display = description .. " → " .. phrase,
      })
    else
      vim.notify("Invalid pair format at index " .. i .. " in phrases file", vim.log.levels.WARN)
    end
  end

  return phrases
end

-- Create the picker function
local function my_snippets()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local phrases = read_phrases()

  if #phrases == 0 then
    vim.notify("No phrases found in " .. phrases_file, vim.log.levels.WARN)
    return
  end

  pickers
    .new({}, {
      prompt_title = "Insert Phrase",
      finder = finders.new_table({
        results = phrases,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.description .. " -> " .. (entry.original:gsub("\n", " "):len() > 30 and entry.original
              :gsub("\n", " ")
              :sub(1, 30) .. "..." or entry.original:gsub("\n", " ")),
            ordinal = entry.description,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.api.nvim_put({ selection.value.expanded }, "c", true, true)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Setup function
function M.setup()
  _G.my_snippets = my_snippets

  -- Add keymap
  vim.keymap.set("n", "<leader>ms", my_snippets, { desc = "My snippets" })
end

return M
