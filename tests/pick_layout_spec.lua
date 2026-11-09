local h = dofile('tests/helpers.lua')

local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

-- Queues keys for getcharstr() without processing them
local function queue(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), 'n', false)
end

local spec = {}

spec['pick_layout sets the picked layout and none clears it'] = function()
  local viewport = require('viewport')
  viewport.setup()
  queue('t')
  viewport.pick_layout()
  local picked = viewport.get_layout()
  queue('n')
  viewport.pick_layout()
  assert_eq({ picked = 'tall', after_none = nil, floats = 0 },
    { picked = picked, after_none = viewport.get_layout(), floats = h.float_count() })
end

spec['pick_layout Esc keeps the current layout'] = function()
  local viewport = require('viewport')
  viewport.setup()
  viewport.set_layout('fat')
  queue('<Esc>')
  viewport.pick_layout()
  assert_eq({ 'fat', 0 }, { viewport.get_layout(), h.float_count() })
end

spec['pick_layout lists every layout with a unique key and marks the current one'] = function()
  local viewport = require('viewport')
  viewport.setup({ layout = { layouts = { tiles = function() end } } })
  viewport.set_layout('vertical')
  local lines
  local open_popup = require('viewport.window').open_popup
  require('viewport.window').open_popup = function(opts)
    lines = opts.buf_lines
    return open_popup(opts)
  end
  queue('<Esc>')
  viewport.pick_layout()
  assert_eq({
    'Choose layout:',
    '[h]orizontal',
    '[v]ertical (current)',
    '[t]all',
    '[f]at',
    't[i]les',
    '[n]one',
    '[Esc] cancel',
  }, lines)
end

spec['none cannot be a layout name'] = function()
  local ok, err = pcall(require('viewport').setup, { layout = { layouts = { none = function() end } } })
  assert_eq({ false, true }, { ok, err:find("'none' is reserved", 1, true) ~= nil })
end

return spec
