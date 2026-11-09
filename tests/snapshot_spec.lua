local snapshot = require('viewport.layout.snapshot')
local arrange = require('viewport.layout.arrange')

local function assert_eq(want, got)
  assert(vim.deep_equal(want, got), 'want ' .. vim.inspect(want) .. ' got ' .. vim.inspect(got))
end

local function sizes()
  local result = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    result[win] = { vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win) }
  end
  return result
end

local function current()
  return { tree = vim.fn.winlayout(), sizes = sizes() }
end

local opts = { main_ratio = 0.5 }
local layouts = { 'horizontal', 'vertical', 'tall', 'fat' }

-- Builds a layout from commands, resizes a window, and returns the windows
local shapes = {
  nested = function()
    vim.cmd('vsplit | split | vsplit')
    vim.api.nvim_win_set_width(0, 12)
  end,
  deep = function()
    vim.cmd('split | vsplit | split | wincmd j | vsplit | vsplit')
    vim.api.nvim_win_set_height(0, 5)
  end,
  quickfix = function()
    vim.cmd('vsplit | split | botright copen')
    vim.api.nvim_win_set_height(0, 4)
  end,
}

local spec = {}

for shape, build in pairs(shapes) do
  for _, name in ipairs(layouts) do
    spec[string.format('restore undoes %s on the %s shape', name, shape)] = function()
      build()
      local want = current()
      local snap = snapshot.take(vim.api.nvim_get_current_tabpage())
      arrange[name](vim.api.nvim_tabpage_list_wins(0), opts)
      snapshot.restore(snap)
      assert_eq(want, current())
    end
  end
end

spec['restore skips windows closed since the snapshot'] = function()
  vim.cmd('vsplit | split')
  local w = vim.api.nvim_tabpage_list_wins(0)
  local snap = snapshot.take(vim.api.nvim_get_current_tabpage())
  arrange.horizontal(w, opts)
  vim.api.nvim_win_close(w[2], false)
  snapshot.restore(snap)
  assert_eq({ 'row', { { 'leaf', w[1] }, { 'leaf', w[3] } } }, vim.fn.winlayout())
end

return spec
