-- lua/lits/config.lua
local M = {}

-- Default configuration
M.default_config = {
  programs_dir = vim.fn.stdpath("data") .. "/lits-programs/",
  default_file = "DEFAULT.lits",
  popup = {
    min_width = 60,
    min_height = 15,
    max_width_ratio = 0.8,
    max_height_ratio = 0.8,
    max_line_width_ratio = 0.6,
    border = "rounded",
  },
}

-- Current configuration (will be set during setup)
M.config = {}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})
  return M.config
end

function M.get()
  return M.config
end

return M
