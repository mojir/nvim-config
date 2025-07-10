local M = {}

-- Centralized ripgrep configuration
M.default_args = {
  "--hidden",
}

-- For find_files command
M.find_files_command = {
  "rg",
  "--files",
  "--hidden",
  "--no-ignore",
  "--glob", "!.git/*",
  "--glob", "!**/.next/*",
  "--glob", "!**/node_modules/*"
}

return M
