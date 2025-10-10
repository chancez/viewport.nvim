local M = {}

-- Sets a keymap and returns the current mapping for restoration
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
-- @param lhs string The left-hand side (key sequence) of the mapping
-- @param rhs function|string The right-hand side (action) of the mapping
-- @param opts table|nil Options to pass to vim.keymap.set
-- @return table The existing mapping that was replaced
function M.set(mode, lhs, rhs, opts)
  -- Get the current global keymap
  -- TODO: Figure out buffer mappings which takes predence over global mappings
  local current_map = vim.fn.maparg(lhs, mode, false, true)
  -- Set the new keymap
  vim.keymap.set(mode, lhs, rhs, opts)
  return current_map
end

return M
