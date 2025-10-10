local M = {}

-- Checks if a value is within a range (inclusive)
-- @param val number The value to check
-- @param lower number The lower bound
-- @param upper number The upper bound
-- @return boolean True if val is between lower and upper (inclusive)
function M.within(val, lower, upper)
  return val >= lower and val <= upper
end

-- Checks if a window is a floating window (has relative positioning)
-- @param id number The window id to check
-- @return boolean True if the window is floating/relative
function M.is_relative(id)
  local conf = vim.api.nvim_win_get_config(id)
  return conf.relative ~= ""
end

return M
