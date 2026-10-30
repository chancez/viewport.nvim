local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

-- Runs scheduled callbacks
local function flush()
  vim.wait(20, function() return false end)
end

local function leaves(wins)
  return vim.tbl_map(function(w) return { 'leaf', w } end, wins)
end

local function setup(opts)
  local viewport = require('viewport')
  viewport.setup(opts)
  return viewport
end

local spec = {}

spec['new and closed windows are rearranged'] = function()
  local viewport = setup()
  local main = vim.api.nvim_get_current_win()
  viewport.set_layout('tall')
  vim.cmd('split')
  local second = vim.api.nvim_get_current_win()
  vim.cmd('split')
  local third = vim.api.nvim_get_current_win()
  flush()
  assert_eq({ 'row', { { 'leaf', main }, { 'col', leaves({ third, second }) } } }, vim.fn.winlayout())

  vim.api.nvim_win_close(third, false)
  vim.cmd('vsplit')
  local fourth = vim.api.nvim_get_current_win()
  flush()
  assert_eq({ 'row', { { 'leaf', main }, { 'col', leaves({ fourth, second }) } } }, vim.fn.winlayout())
end

spec['closing the main window promotes the next one'] = function()
  local viewport = setup()
  local main = vim.api.nvim_get_current_win()
  viewport.set_layout('fat')
  vim.cmd('split | split')
  flush()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  vim.api.nvim_win_close(main, false)
  flush()
  assert_eq({ 'col', { { 'leaf', wins[2] }, { 'leaf', wins[3] } } }, vim.fn.winlayout())
end

spec['floating windows do not rearrange or resize'] = function()
  local viewport = setup()
  viewport.set_layout('tall')
  vim.cmd('split')
  flush()
  local main = vim.api.nvim_tabpage_list_wins(0)[1]
  vim.api.nvim_win_set_width(main, 20)
  vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false,
    { relative = 'editor', row = 1, col = 1, width = 5, height = 1 })
  flush()
  assert_eq(20, vim.api.nvim_win_get_width(main))
end

spec['clearing the layout stops rearranging'] = function()
  local viewport = setup()
  viewport.set_layout('horizontal')
  viewport.set_layout(nil)
  vim.cmd('split')
  flush()
  assert_eq('col', vim.fn.winlayout()[1])
end

spec['each tabpage has its own layout'] = function()
  local viewport = setup()
  viewport.set_layout('horizontal')
  local first_tab = vim.api.nvim_get_current_tabpage()
  vim.cmd('tabnew | split')
  flush()
  assert_eq({ 'col', nil }, { vim.fn.winlayout()[1], viewport.get_layout() })

  vim.cmd('tabprevious | split')
  flush()
  assert_eq({ 'row', 'horizontal', 'horizontal' },
    { vim.fn.winlayout()[1], viewport.get_layout(), vim.t[first_tab].viewport_layout })
end

spec['make_main moves a window into the main position'] = function()
  local viewport = setup()
  local main = vim.api.nvim_get_current_win()
  viewport.set_layout('tall')
  vim.cmd('split')
  local other = vim.api.nvim_get_current_win()
  flush()
  require('viewport.actions').make_main()
  assert_eq({ 'row', leaves({ other, main }) }, vim.fn.winlayout())
end

spec['next_layout cycles through every layout'] = function()
  local viewport = setup({ layout = { layouts = { custom = function() end } } })
  local seen = {}
  for _ = 1, 6 do
    viewport.next_layout()
    table.insert(seen, viewport.get_layout())
  end
  assert_eq({ 'horizontal', 'vertical', 'tall', 'fat', 'custom', 'horizontal' }, seen)
end

spec['toggle_layout sets and clears a layout'] = function()
  local viewport = setup()
  viewport.toggle_layout('vertical')
  local set = viewport.get_layout()
  viewport.toggle_layout('vertical')
  assert_eq({ 'vertical', nil }, { set, viewport.get_layout() })
end

spec['unknown layout errors'] = function()
  local viewport = setup()
  local ok, err = pcall(viewport.set_layout, 'nope')
  assert_eq({ false, true }, { ok, err:find("Unknown layout 'nope'", 1, true) ~= nil })
end

spec['layout change autocmd reports each change'] = function()
  local viewport = setup()
  local events = {}
  vim.api.nvim_create_autocmd('User', {
    pattern = viewport.layout_change_autocmd,
    callback = function(ev) table.insert(events, ev.data.layout or 'none') end,
  })
  viewport.set_layout('tall')
  viewport.next_layout()
  viewport.set_layout(nil)
  assert_eq({ 'tall', 'fat', 'none' }, events)
end

return spec
