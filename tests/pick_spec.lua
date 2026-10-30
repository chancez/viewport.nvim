local h = dofile('tests/helpers.lua')

-- Queues keys for getcharstr() without processing them
local function queue(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), 'n', false)
end

-- Sets up viewport with two side by side windows and returns them left to right
local function setup()
  local viewport = require('viewport')
  viewport.setup()
  vim.cmd('vsplit')
  vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
  return viewport, vim.api.nvim_tabpage_list_wins(0)
end

local function state()
  return {
    win = vim.api.nvim_get_current_win(),
    floats = h.float_count(),
    mode = vim.g.viewport_active_mode,
  }
end

local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

local spec = {}

spec['select focus focuses the picked window and leaves no state'] = function()
  local viewport, wins = setup()
  queue('bf')
  viewport.start_select_mode()
  assert_eq({ win = wins[2], floats = 0, mode = nil }, state())
end

spec['select cancel with Esc leaves no state'] = function()
  local viewport, wins = setup()
  queue('<Esc>')
  viewport.start_select_mode()
  assert_eq({ win = wins[1], floats = 0, mode = nil }, state())
  queue('b<Esc>')
  viewport.start_select_mode()
  assert_eq({ win = wins[1], floats = 0, mode = nil }, state())
end

spec['select resize starts resize, and Esc does not restart select'] = function()
  local viewport, wins = setup()
  queue('br')
  viewport.start_select_mode()
  -- One float for the resize mappings display
  assert_eq({ win = wins[2], floats = 1, mode = 'resize' }, state())

  h.feed('<Esc>')
  assert_eq({ win = wins[2], floats = 0, mode = nil }, state())

  viewport.start_resize_mode()
  h.feed('<Esc>')
  assert_eq({ win = wins[2], floats = 0, mode = nil }, state())
end

spec['select swap swaps the picked window with another'] = function()
  local viewport, wins = setup()
  local left_buf = vim.api.nvim_win_get_buf(wins[1])
  local right_buf = vim.api.nvim_win_get_buf(wins[2])
  -- Pick the right window, choose swap, then pick the only other window
  queue('bsa')
  viewport.start_select_mode()
  assert_eq({ right_buf, left_buf }, {
    vim.api.nvim_win_get_buf(wins[1]),
    vim.api.nvim_win_get_buf(wins[2]),
  })
  assert_eq(0, h.float_count())
end

spec['select_window inside navigate mode keeps navigate mode'] = function()
  local viewport, wins = setup()
  viewport.start_navigate_mode()
  h.feed('sb')
  assert_eq({ win = wins[2], floats = 1, mode = 'navigate' }, state())
  h.feed('h')
  assert_eq({ win = wins[1], floats = 1, mode = 'navigate' }, state())
  h.feed('<Esc>')
  assert_eq({ win = wins[1], floats = 0, mode = nil }, state())
end

return spec
