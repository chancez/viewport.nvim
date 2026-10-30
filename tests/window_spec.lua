local window = require('viewport.window')

local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

local spec = {}

spec['place moves a window next to another and keeps its state'] = function()
  vim.cmd('split')
  local wins = vim.api.nvim_tabpage_list_wins(0)
  vim.w[wins[2]].tag = 'kept'
  window.new(wins[2]):place('right', wins[1])
  assert_eq({
    layout = { 'row', { { 'leaf', wins[1] }, { 'leaf', wins[2] } } },
    tag = 'kept',
  }, {
    layout = vim.fn.winlayout(),
    tag = vim.w[wins[2]].tag,
  })
end

spec['place rejects an unknown direction'] = function()
  vim.cmd('split')
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local ok, err = pcall(window.Window.place, window.new(wins[2]), 'sideways', wins[1])
  assert_eq({ false, true }, { ok, err:find("Invalid direction 'sideways'", 1, true) ~= nil })
end

return spec
