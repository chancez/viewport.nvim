local h = dofile('tests/helpers.lua')

local function setup()
  local viewport = require('viewport')
  viewport.setup()
  vim.cmd('vsplit')
  return viewport
end

local function state(viewport)
  return {
    mode = vim.g.viewport_active_mode,
    resize = viewport.controller:get('resize').active,
    navigate = viewport.controller:get('navigate').active,
    floats = h.float_count(),
    esc = h.buf_mapping_descs('<Esc>', { vim.api.nvim_get_current_buf() })[vim.api.nvim_get_current_buf()],
  }
end

local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

local stopped = { mode = nil, resize = false, navigate = false, floats = 0, esc = vim.NIL }

local spec = {}

spec['starting the active mode again then Esc stops it'] = function()
  local viewport = setup()
  viewport.start_resize_mode()
  viewport.start_resize_mode()
  h.feed('<Esc>')
  assert_eq(stopped, state(viewport))
end

spec['starting a mode stops the active one, and Esc stops everything'] = function()
  local viewport = setup()
  viewport.start_resize_mode()
  viewport.start_navigate_mode()
  assert_eq({ mode = 'navigate', resize = false, navigate = true, floats = 1, esc = 'Action: stop' }, state(viewport))
  h.feed('<Esc>')
  assert_eq(stopped, state(viewport))
end

spec['toggle starts and stops a mode'] = function()
  local viewport = setup()
  viewport.toggle_mode('resize')
  assert_eq({ mode = 'resize', resize = true, navigate = false, floats = 1, esc = 'Action: stop' }, state(viewport))
  viewport.toggle_mode('resize')
  assert_eq(stopped, state(viewport))
end

spec['mode change autocmd reports each change'] = function()
  local viewport = setup()
  local events = {}
  vim.api.nvim_create_autocmd('User', {
    pattern = viewport.mode_change_autocmd,
    callback = function(ev) table.insert(events, ev.data.mode or 'none') end,
  })
  viewport.start_resize_mode()
  viewport.start_navigate_mode()
  h.feed('<Esc>')
  assert_eq({ 'resize', 'none', 'navigate', 'none' }, events)
end

spec['mappings display toggle keeps the mode running'] = function()
  local viewport = setup()
  viewport.start_resize_mode()
  h.feed('<Tab>')
  assert_eq({ mode = 'resize', resize = true, navigate = false, floats = 0, esc = 'Action: stop' }, state(viewport))
end

return spec
