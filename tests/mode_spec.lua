local h = dofile('tests/helpers.lua')

local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

local spec = {}

spec['on_stop can start the same mode again'] = function()
  local m = require('viewport.mode').new({ mappings = { n = { x = function() end } } })
  local restarts = 0
  m:start(function(stopped_mode)
    restarts = restarts + 1
    stopped_mode:start()
  end)
  m:stop()
  local buf = vim.api.nvim_get_current_buf()
  assert_eq({ active = true, restarts = 1, x = 'Viewport Action' }, {
    active = m.active,
    restarts = restarts,
    x = h.buf_mapping_descs('x', { buf })[buf],
  })
end

return spec
