local window = require('viewport.window')

-- Saves the window tree and window sizes of a tabpage so they can be
-- restored later, keeping each window's id and state.
local snapshot = {}

-- @class Snapshot
-- @field tree table The tree returned by winlayout()
-- @field sizes table<number, number[]> Width and height by window id

-- Takes a snapshot of a tabpage's split windows. Floats are not included.
-- @param tab number Tabpage handle
-- @return Snapshot The snapshot
function snapshot.take(tab)
  local tree = vim.fn.winlayout(vim.api.nvim_tabpage_get_number(tab))
  local sizes = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.api.nvim_win_get_config(win).relative == '' then
      sizes[win] = { vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win) }
    end
  end
  return { tree = tree, sizes = sizes }
end

-- Removes closed windows from a tree, collapsing containers left with one child
-- @return table|nil The pruned tree, or nil if no windows are left
local function prune(node)
  if node[1] == 'leaf' then
    return vim.api.nvim_win_is_valid(node[2]) and node or nil
  end
  local children = {}
  for _, child in ipairs(node[2]) do
    table.insert(children, prune(child))
  end
  if #children == 0 then
    return nil
  elseif #children == 1 then
    return children[1]
  end
  return { node[1], children }
end

-- Returns the first window in a tree
local function first_window(node)
  while node[1] ~= 'leaf' do
    node = node[2][1]
  end
  return node[2]
end

-- Moves windows into the shape of node. Each child's first window is placed
-- after the previous child's first window, then each child is built around
-- its first window.
local function build(node)
  if node[1] == 'leaf' then
    return
  end
  local direction = node[1] == 'row' and 'right' or 'down'
  local children = node[2]
  for i = 2, #children do
    window.new(first_window(children[i])):place(direction, first_window(children[i - 1]))
  end
  for _, child in ipairs(children) do
    build(child)
  end
end

-- Returns the split windows of the tabpage containing win, sorted
local function split_windows(win)
  local wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ''
  end, vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)))
  table.sort(wins)
  return wins
end

-- Restores a snapshot. Windows closed since it was taken are skipped, and
-- windows opened since stay where they are. Sizes are only restored if the
-- tabpage has the same windows, otherwise windows are equalized.
-- @param snap Snapshot The snapshot to restore
function snapshot.restore(snap)
  local tree = prune(snap.tree)
  if not tree then
    return
  end
  build(tree)

  local anchor = first_window(tree)
  local saved = vim.tbl_keys(snap.sizes)
  table.sort(saved)
  if not vim.deep_equal(saved, split_windows(anchor)) then
    vim.api.nvim_win_call(anchor, function()
      vim.cmd('wincmd =')
    end)
    return
  end
  -- Setting one size moves its neighbours, so a second pass settles them
  for _ = 1, 2 do
    for win, size in pairs(snap.sizes) do
      vim.api.nvim_win_set_width(win, size[1])
      vim.api.nvim_win_set_height(win, size[2])
    end
  end
end

return snapshot
