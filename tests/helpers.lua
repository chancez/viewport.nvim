local M = {}

-- Feeds keys as if typed, processing them immediately
function M.feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), 'x', false)
end

-- Returns the desc of each buffer-local normal mode mapping for lhs, keyed by buffer
function M.buf_mapping_descs(lhs, bufs)
  local result = {}
  for _, buf in ipairs(bufs) do
    result[buf] = vim.NIL
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, 'n')) do
      if m.lhs == lhs then
        result[buf] = m.desc or ''
      end
    end
  end
  return result
end

-- Returns the number of floating windows
function M.float_count()
  return #vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative ~= ''
  end, vim.api.nvim_list_wins())
end

return M
