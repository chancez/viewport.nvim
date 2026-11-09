local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

-- Creates :ViewportLayout the way the README describes
local function setup()
  local viewport = require('viewport')
  viewport.setup()
  local layout_cmd = require('viewport.commands').layout
  vim.api.nvim_create_user_command('ViewportLayout', layout_cmd.run, {
    nargs = '?',
    complete = layout_cmd.complete,
  })
  return viewport
end

local spec = {}

spec['ViewportLayout sets and clears layouts'] = function()
  local viewport = setup()
  vim.cmd('ViewportLayout tall')
  local set = viewport.get_layout()
  vim.cmd('ViewportLayout none')
  assert_eq({ 'tall', nil }, { set, viewport.get_layout() })
end

spec['ViewportLayout without a name opens the picker'] = function()
  local viewport = setup()
  vim.api.nvim_feedkeys('f', 'n', false)
  vim.cmd('ViewportLayout')
  assert_eq('fat', viewport.get_layout())
end

spec['ViewportLayout reports an unknown layout'] = function()
  local viewport = setup()
  local messages = {}
  local notify = vim.notify
  vim.notify = function(msg) table.insert(messages, msg) end
  vim.cmd('ViewportLayout nope')
  vim.notify = notify
  assert_eq({ { "viewport: unknown layout 'nope'" }, nil }, { messages, viewport.get_layout() })
end

spec['ViewportLayout completes layout names'] = function()
  setup()
  assert_eq({
    all = { 'horizontal', 'vertical', 'tall', 'fat', 'none' },
    t = { 'tall' },
  }, {
    all = vim.fn.getcompletion('ViewportLayout ', 'cmdline'),
    t = vim.fn.getcompletion('ViewportLayout t', 'cmdline'),
  })
end

return spec
