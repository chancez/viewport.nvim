local arrange = require('viewport.layout.arrange')

local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

-- Creates four windows in a nested layout and returns them in layout order
local function messy()
  vim.cmd('vsplit | split | vsplit')
  return vim.api.nvim_tabpage_list_wins(0)
end

local function leaves(wins)
  return vim.tbl_map(function(w) return { 'leaf', w } end, wins)
end

local opts = { main_ratio = 0.5 }

local spec = {}

spec['horizontal puts every window in one row'] = function()
  local w = messy()
  arrange.horizontal(w, opts)
  assert_eq({ 'row', leaves(w) }, vim.fn.winlayout())
end

spec['vertical puts every window in one column'] = function()
  local w = messy()
  arrange.vertical(w, opts)
  assert_eq({ 'col', leaves(w) }, vim.fn.winlayout())
end

spec['tall puts the main window left of a column'] = function()
  local w = messy()
  arrange.tall(w, opts)
  assert_eq({ 'row', { { 'leaf', w[1] }, { 'col', leaves({ w[2], w[3], w[4] }) } } }, vim.fn.winlayout())
end

spec['fat puts the main window above a row'] = function()
  local w = messy()
  arrange.fat(w, opts)
  assert_eq({ 'col', { { 'leaf', w[1] }, { 'row', leaves({ w[2], w[3], w[4] }) } } }, vim.fn.winlayout())
end

spec['tall sizes the main window by main_ratio'] = function()
  local w = messy()
  arrange.tall(w, { main_ratio = 0.6 })
  assert_eq(math.floor(vim.o.columns * 0.6), vim.api.nvim_win_get_width(w[1]))
end

spec['arrange uses the given main window'] = function()
  local w = messy()
  arrange.tall({ w[3], w[1], w[2], w[4] }, opts)
  assert_eq({ 'row', { { 'leaf', w[3] }, { 'col', leaves({ w[1], w[2], w[4] }) } } }, vim.fn.winlayout())
end

spec['arrange leaves windows not given in place'] = function()
  vim.cmd('vsplit')
  local w = vim.api.nvim_tabpage_list_wins(0)
  vim.cmd('botright copen')
  local qf = vim.api.nvim_get_current_win()
  arrange.vertical(w, opts)
  assert_eq({ 'col', { { 'leaf', w[1] }, { 'leaf', w[2] }, { 'leaf', qf } } }, vim.fn.winlayout())
end

spec['single window is left alone'] = function()
  local w = vim.api.nvim_tabpage_list_wins(0)
  for _, name in ipairs({ 'horizontal', 'vertical', 'tall', 'fat' }) do
    arrange[name](w, opts)
  end
  assert_eq({ 'leaf', w[1] }, vim.fn.winlayout())
end

return spec
