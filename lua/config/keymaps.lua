-- Global keymaps that don't belong to specific plugins

vim.keymap.set("n", "<leader>U", ":Lazy update<CR>", { desc = "Lazy update" })

-- Simple keymap to quit all
vim.keymap.set("n", "<leader>qa", ":qall<CR>", { desc = "Quit all" })
vim.keymap.set("n", "<leader>qw", ":Wqall!<CR>", { desc = "Save and quit all!" })

-- Window navigation with Option+Arrow keys
local nav_maps = {
  ["<M-Left>"] = "<C-w>h",
  ["<M-Right>"] = "<C-w>l",
  ["<M-Up>"] = "<C-w>k",
  ["<M-Down>"] = "<C-w>j",
}

for key, cmd in pairs(nav_maps) do
  vim.keymap.set("n", key, cmd, { desc = "Navigate windows" })
  vim.keymap.set("t", key, "<C-\\><C-n>" .. cmd, { desc = "Navigate from terminal" })
end

vim.keymap.set("n", "<leader>bc", function()
  vim.cmd("silent! %bdelete|edit#|bdelete#")
  print("Closed all buffers except current")
end, { desc = "Close all but current" })

vim.keymap.set("n", "gp", function()
  local start_mark = vim.api.nvim_buf_get_mark(0, "[")
  local end_mark = vim.api.nvim_buf_get_mark(0, "]")

  if start_mark[1] > 0 and end_mark[1] > 0 then
    vim.api.nvim_win_set_cursor(0, start_mark)
    vim.cmd("normal! v")
    vim.api.nvim_win_set_cursor(0, end_mark)
  else
    print("No recent paste to select")
  end
end, { desc = "Select last pasted text" })

-- Clipboard operations using + register
vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank to clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from clipboard after cursor" })
vim.keymap.set("n", "<leader>P", '"+P', { desc = "Paste from clipboard before cursor" })
vim.keymap.set("v", "<leader>p", '"+p', { desc = "Paste from clipboard" })

-- copy current buffer's relative path
vim.keymap.set("n", "<leader>cp", function()
  local relative_path = vim.fn.expand("%")
  if relative_path == "" then
    print("No file in current buffer")
    return
  end

  vim.fn.setreg("+", relative_path)
  vim.fn.setreg('"', relative_path)
  print("Copied: " .. relative_path)
end, { desc = "Copy current buffer's relative path" })

-- Copy absolute path
vim.keymap.set("n", "<leader>cP", function()
  local absolute_path = vim.fn.expand("%:p")
  if absolute_path == "" then
    print("No file in current buffer")
    return
  end
  vim.fn.setreg("+", absolute_path)
  vim.fn.setreg('"', absolute_path)
  print("Copied absolute: " .. absolute_path)
end, { desc = "Copy current buffer's absolute path" })

-- Map mouse back/forward to jump list navigation
vim.keymap.set("n", "<X1Mouse>", "<C-o>", { desc = "Jump back" })
vim.keymap.set("n", "<X2Mouse>", "<C-i>", { desc = "Jump forward" })
vim.keymap.set("n", "<2-X1Mouse>", "<C-o>", { desc = "Jump back (double)" })
vim.keymap.set("n", "<2-X2Mouse>", "<C-i>", { desc = "Jump forward (double)" })
vim.keymap.set("n", "<leader><Left>", "<C-o>", { desc = "Jump back" })
vim.keymap.set("n", "<leader><Right>", "<C-i>", { desc = "Jump forward" })

-- For my muscle memory, map ,c<space> to gc
vim.keymap.set("n", "<leader>c<space>", "gcc", { desc = "Toggle comment line", remap = true })
vim.keymap.set("v", "<leader>c<space>", "gc", { desc = "Toggle comment selection", remap = true })

vim.keymap.set("n", "<leader>tq", function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, { desc = "Toggle quickfix" })

-- Load utility functions for diagnostics
require("utils.diagnostic")

-- Simple function to close all buffers outside nvim-tree root
local function close_buffers_outside_root()
  local root_path = vim.fn.getcwd()
  local closed_count = 0

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local buftype = vim.bo[bufnr].buftype

      -- Only check regular file buffers
      if buftype == "" and bufname ~= "" then
        local buf_dir = vim.fn.fnamemodify(bufname, ":p:h")

        -- Check if buffer is outside root directory
        -- Normalize paths to ensure proper comparison
        local normalized_buf_dir = vim.fn.resolve(buf_dir)
        local normalized_root = vim.fn.resolve(root_path)

        -- Check if buffer path starts with root path
        local is_under_root = normalized_buf_dir:find("^" .. vim.pesc(normalized_root))

        if not is_under_root then
          pcall(function()
            vim.bo[bufnr].modified = false
            vim.api.nvim_buf_delete(bufnr, { force = true })
            closed_count = closed_count + 1
          end)
        end
      end
    end
  end

  print(string.format("Closed %d buffer(s) outside root: %s", closed_count, root_path))
end

-- Create the command
vim.api.nvim_create_user_command("CloseOutsideRoot", close_buffers_outside_root, {
  desc = "Close all file buffers outside nvim-tree root directory",
})

local function diff_two_files()
  local file1 = nil

  -- First file selection
  require("telescope.builtin").find_files({
    prompt_title = "Select first file",
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        file1 = selection.path
        require("telescope.actions").close(prompt_bufnr)

        -- Second file selection
        vim.defer_fn(function()
          require("telescope.builtin").find_files({
            prompt_title = "Select second file",
            attach_mappings = function(_, map2)
              map2("i", "<CR>", function(prompt_bufnr2)
                local selection2 = require("telescope.actions.state").get_selected_entry()
                require("telescope.actions").close(prompt_bufnr2)

                -- Open diff
                vim.cmd("tabnew")
                vim.cmd("edit " .. file1)
                vim.cmd("vsplit " .. selection2.path)
                vim.cmd("windo diffthis")
              end)
              return true
            end,
          })
        end, 100)
      end)
      return true
    end,
  })
end

vim.keymap.set("n", "<leader>d2", diff_two_files, { desc = "Diff two files (Telescope)" })

-- Define the smart format function once
local function smart_format()
  local ft = vim.bo.filetype

  if vim.tbl_contains({
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  }, ft) then
    vim.lsp.buf.format({
      filter = function(client)
        return client.name == "null-ls"
      end,
      async = false,
    })
    print("Formatted with ESLint")
  elseif ft == "lua" then
    -- Save the buffer first if modified
    if vim.bo.modified then
      vim.cmd("silent write")
    end

    local view = vim.fn.winsaveview()
    vim.cmd("silent !stylua --config-path ~/.config/stylua/stylua.toml %")
    vim.cmd("keepmarks edit!")
    vim.fn.winrestview(view)
    print("Formatted with StyLua")
  else
    vim.lsp.buf.format({ async = false })
    print("Formatted with LSP")
  end
end

-- Keep your explicit formatter
vim.keymap.set({ "n" }, "<leader>lf", smart_format, { desc = "Format with appropriate formatter" })

-- JSON formatting with jq
vim.keymap.set("v", "<leader>jf", function()
  -- Check if jq is available
  local handle = io.popen("command -v jq >/dev/null 2>&1 && echo 'exists'")
  local jq_exists = handle and handle:read("*a"):match("exists")
  if handle then
    handle:close()
  end

  if not jq_exists then
    print("jq not found. Install with: brew install jq")
    return
  end

  -- Exit visual mode first to set the marks, then run the command
  vim.cmd("normal! :")
  vim.cmd("'<,'>!jq .")
  print("JSON formatted")
end, { desc = "Format selected JSON" })

-- JSON minify
vim.keymap.set("v", "<leader>jm", function()
  local handle = io.popen("command -v jq >/dev/null 2>&1 && echo 'exists'")
  local jq_exists = handle and handle:read("*a"):match("exists")
  if handle then
    handle:close()
  end

  if not jq_exists then
    print("jq not found. Install with: brew install jq")
    return
  end

  -- Exit visual mode first to set the marks, then run the command
  vim.cmd("normal! :")
  vim.cmd("'<,'>!jq -c .")
  print("JSON minified")
end, { desc = "Minify selected JSON" })

vim.keymap.set("n", "<leader>na", function()
  local note = vim.fn.input("Note: ")
  if note == "" then
    print("Note cancelled")
    return
  end

  local notes_unexpanded_file = "~/notes/_notes.md"
  local notes_file = vim.fn.expand(notes_unexpanded_file)
  local timestamp = os.date("%Y-%m-%d %H:%M")
  local note_line = "* " .. timestamp .. " " .. note

  -- Create directory if it doesn't exist
  local notes_dir = vim.fn.fnamemodify(notes_file, ":h")
  if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, "p")
  end

  -- Append to file
  local file = io.open(notes_file, "a")
  if file then
    file:write(note_line .. "\n")
    file:close()
    print("Note added to " .. notes_file)
  else
    print("Error: Could not write to " .. notes_unexpanded_file)
  end
end, { desc = "Add note to ~/nodes/_notes.md" })

vim.keymap.set("n", "<leader><Tab>", "<C-^>", { desc = "Toggle last buffer" })

