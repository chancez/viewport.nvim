local M = {}

-- Returns true if a is between b and c (inclusive)
-- @param val The value to check
-- @param lower The lower bound
-- @param upper The upper bound
function M.within(val, lower, upper)
  return val >= lower and val <= upper
end

function M.is_relative(id)
  local conf = vim.api.nvim_win_get_config(id)
  return conf.relative ~= ""
end

return M
