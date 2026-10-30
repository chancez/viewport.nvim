local keymap = require('viewport.mode.keymap')
local h = dofile('tests/helpers.lua')

local spec = {}

spec['restore puts buffer-local mappings back in their own buffer'] = function()
  local b1 = vim.api.nvim_get_current_buf()
  vim.keymap.set('n', 'k', function() end, { buffer = b1, desc = 'user-k' })
  vim.cmd('vsplit')
  local b2 = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(b2)

  local km = keymap.new()
  km:save({ 'n' })
  km:set('n', 'k', function() end, { desc = 'mode-k' })
  assert(vim.deep_equal(h.buf_mapping_descs('k', { b1, b2 }), { [b1] = 'mode-k', [b2] = 'mode-k' }))

  km:restore()
  local got = h.buf_mapping_descs('k', { b1, b2 })
  assert(vim.deep_equal(got, { [b1] = 'user-k', [b2] = vim.NIL }), vim.inspect(got))
end

spec['restore removes mappings set on buffers entered later'] = function()
  local km = keymap.new()
  km:save({ 'n' })
  km:set('n', 'k', function() end, { desc = 'mode-k' })
  local b2 = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(b2)
  assert(vim.deep_equal(h.buf_mapping_descs('k', { b2 }), { [b2] = 'mode-k' }))

  km:restore()
  local got = h.buf_mapping_descs('k', { b2 })
  assert(vim.deep_equal(got, { [b2] = vim.NIL }), vim.inspect(got))
end

return spec
