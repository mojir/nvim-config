local M = {}

-- Configuration constants
M.HISTORY_LIMIT = 100
M.DATA_VERSION = "1.0"

-- Paths
M.session_dir = vim.fn.stdpath("data") .. "/sessions/"

-- Session options
M.session_options = "buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"

-- Register filter (only a-z)
M.registers_to_save = {}
for i = string.byte('a'), string.byte('z') do
  table.insert(M.registers_to_save, string.char(i))
end

-- File naming functions
function M.get_session_name()
  local cwd = vim.fn.getcwd()
  return vim.fn.substitute(cwd, "[/\\:]", "_", "g")
end

function M.get_session_file()
  return M.get_session_dir() .. "/session.vim"
end

function M.get_data_file()
  return M.get_session_dir() .. "/data.json"
end

function M.get_session_dir()
  return M.session_dir .. M.get_session_name() .. "/"
end

-- Ensure session directory exists
function M.ensure_session_dir()
  vim.fn.mkdir(M.session_dir, "p")
  vim.fn.mkdir(M.get_session_dir(), "p")
end

return M
