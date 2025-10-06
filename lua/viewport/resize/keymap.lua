local M = {}

-- a helper function to set a keymap and return the current mapping
function M.set(mode, lhs, rhs, opts)
  -- Get the current global keymap
  -- TODO: Figure out buffer mappings which takes predence over global mappings
  local current_map = vim.fn.maparg(lhs, mode, false, true)
  -- Set the new keymap
  vim.keymap.set(mode, lhs, rhs, opts)
  return current_map
end

return M
