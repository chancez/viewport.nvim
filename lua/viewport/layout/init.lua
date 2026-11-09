local arrange = require('viewport.layout.arrange')
local snapshot = require('viewport.layout.snapshot')

-- Built-in layouts, in the order next() cycles through them
local builtin_order = { 'horizontal', 'vertical', 'tall', 'fat' }

-- Excludes floating windows and special buffers like help and quickfix
-- @param win number Window id
-- @return boolean True if the window should not be arranged
local function default_should_exclude_window(win)
  if vim.api.nvim_win_get_config(win).relative ~= '' then
    return true
  end
  local buftype = vim.bo[vim.api.nvim_win_get_buf(win)].buftype
  return buftype ~= '' and buftype ~= 'terminal'
end

-- Applies a layout to each tabpage that has one, and keeps applying it as
-- windows are opened and closed. Each tabpage has its own layout, or none.
local Manager = {}
Manager.__index = Manager

-- @class LayoutManagerOpts
-- @field layouts table<string, function>|nil Extra arrange functions by name. See viewport.layout.arrange
-- @field main_ratio number|nil Fraction of the tab given to the main window in tall and fat (default 0.5)
-- @field should_exclude_window function|nil Takes a window id, returns true to leave the window out
-- @field on_change function|nil Called with the tabpage and layout name, or nil, when a layout is set

-- Creates a new layout manager
-- @param opts LayoutManagerOpts|nil Options for the manager
-- @return Manager A new layout manager
function Manager.new(opts)
  opts = opts or {}
  vim.validate("layouts", opts.layouts, { 'table', 'nil' })
  vim.validate("main_ratio", opts.main_ratio, { 'number', 'nil' })
  vim.validate("should_exclude_window", opts.should_exclude_window, { 'function', 'nil' })
  vim.validate("on_change", opts.on_change, { 'function', 'nil' })

  local self = setmetatable({}, Manager)
  self._layouts = {}
  self._order = {}
  for _, name in ipairs(builtin_order) do
    self:_add_layout(name, arrange[name])
  end
  local extra = vim.tbl_keys(opts.layouts or {})
  table.sort(extra)
  for _, name in ipairs(extra) do
    self:_add_layout(name, opts.layouts[name])
  end
  self._arrange_opts = { main_ratio = opts.main_ratio or 0.5 }
  self._should_exclude_window = opts.should_exclude_window or default_should_exclude_window
  self._on_change = opts.on_change or function(_, _) end
  -- Layout state by tabpage handle: { name, main, wins, snapshot }
  self._tabs = {}
  self._augroup = nil
  self._pending = false
  return self
end

function Manager:_add_layout(name, fn)
  vim.validate("layout " .. name, fn, 'function')
  if name == 'none' then
    error("'none' is reserved for clearing the layout and cannot be a layout name")
  end
  if not self._layouts[name] then
    table.insert(self._order, name)
  end
  self._layouts[name] = fn
end

-- Returns the windows to arrange in a tabpage, in layout order
function Manager:_windows(tab)
  return vim.tbl_filter(function(win)
    return not self._should_exclude_window(win)
  end, vim.api.nvim_tabpage_list_wins(tab))
end

-- Arranges a tabpage's windows if they changed since the last arrange, or
-- always when force is true.
-- @param tab number Tabpage handle
-- @param force boolean|nil Arrange even if the windows have not changed
function Manager:apply(tab, force)
  local state = self._tabs[tab]
  if not state or not vim.api.nvim_tabpage_is_valid(tab) then
    return
  end
  local wins = self:_windows(tab)
  if not vim.tbl_contains(wins, state.main) then
    state.main = wins[1]
  end
  -- Main window first, the rest in layout order
  wins = vim.list_extend({ state.main }, vim.tbl_filter(function(win)
    return win ~= state.main
  end, wins))

  if not force and vim.deep_equal(wins, state.wins) then
    return
  end
  state.wins = wins
  if #wins == 0 then
    return
  end
  local ok, err = pcall(self._layouts[state.name], wins, self._arrange_opts)
  if not ok then
    vim.notify(string.format("viewport: %s layout failed: %s", state.name, err), vim.log.levels.WARN)
  end
end

-- Arranges every tabpage with a layout on the next event loop iteration.
-- Autocmds fire while windows are still being created or closed, so
-- arranging immediately is not safe.
function Manager:_schedule_apply(force)
  if self._pending then
    return
  end
  self._pending = true
  vim.schedule(function()
    self._pending = false
    for tab in pairs(self._tabs) do
      if vim.api.nvim_tabpage_is_valid(tab) then
        self:apply(tab, force)
      else
        self._tabs[tab] = nil
      end
    end
  end)
end

function Manager:_update_autocmds()
  if next(self._tabs) == nil then
    if self._augroup then
      vim.api.nvim_del_augroup_by_id(self._augroup)
      self._augroup = nil
    end
    return
  end
  if self._augroup then
    return
  end
  self._augroup = vim.api.nvim_create_augroup(string.format('ViewportLayout_%s', self), { clear = true })
  vim.api.nvim_create_autocmd({ 'WinNew', 'WinClosed' }, {
    group = self._augroup,
    callback = function()
      self:_schedule_apply(false)
    end,
  })
  vim.api.nvim_create_autocmd('VimResized', {
    group = self._augroup,
    callback = function()
      self:_schedule_apply(true)
    end,
  })
  vim.api.nvim_create_autocmd('TabClosed', {
    group = self._augroup,
    callback = function()
      for tab in pairs(self._tabs) do
        if not vim.api.nvim_tabpage_is_valid(tab) then
          self._tabs[tab] = nil
        end
      end
      self:_update_autocmds()
    end,
  })
end

-- Sets the layout of a tabpage and arranges it. The current window becomes
-- the main window. Setting the first layout on a tabpage saves its windows,
-- and clearing the layout restores them.
-- @param name string|nil Layout name, or nil to stop arranging the tabpage
-- @param tab number|nil Tabpage handle (defaults to the current tabpage)
-- @error Throws an error if the layout does not exist
function Manager:set(name, tab)
  vim.validate("name", name, { 'string', 'nil' })
  tab = (tab == nil or tab == 0) and vim.api.nvim_get_current_tabpage() or tab
  if name and not self._layouts[name] then
    error(string.format("Unknown layout '%s'. Valid layouts are: %s", name, table.concat(self._order, ", ")))
  end

  local previous = self._tabs[tab]
  if name then
    self._tabs[tab] = {
      name = name,
      main = vim.api.nvim_tabpage_get_win(tab),
      wins = nil,
      -- Keep the windows from before the first layout when switching layouts
      snapshot = previous and previous.snapshot or snapshot.take(tab),
    }
  else
    self._tabs[tab] = nil
  end
  self:_update_autocmds()
  self._on_change(tab, name)
  if name then
    self:apply(tab, true)
  elseif previous then
    local ok, err = pcall(snapshot.restore, previous.snapshot)
    if not ok then
      vim.notify(string.format("viewport: restoring windows failed: %s", err), vim.log.levels.WARN)
    end
  end
end

-- Returns the layout of a tabpage, if any
-- @param tab number|nil Tabpage handle (defaults to the current tabpage)
-- @return string|nil The layout name
function Manager:get(tab)
  tab = (tab == nil or tab == 0) and vim.api.nvim_get_current_tabpage() or tab
  local state = self._tabs[tab]
  return state and state.name
end

-- Sets the layout of a tabpage, or clears it if it is already set
-- @param name string Layout name
-- @param tab number|nil Tabpage handle (defaults to the current tabpage)
function Manager:toggle(name, tab)
  if self:get(tab) == name then
    self:set(nil, tab)
  else
    self:set(name, tab)
  end
end

-- Sets the layout after the current one, or the first layout if none is set
-- @param tab number|nil Tabpage handle (defaults to the current tabpage)
function Manager:next(tab)
  local current = self:get(tab)
  local index = 0
  for i, name in ipairs(self._order) do
    if name == current then
      index = i
    end
  end
  self:set(self._order[index % #self._order + 1], tab)
end

-- Makes a window the main window of its tabpage's layout and rearranges
-- @param win number|nil Window id (defaults to the current window)
function Manager:make_main(win)
  win = (win == nil or win == 0) and vim.api.nvim_get_current_win() or win
  local tab = vim.api.nvim_win_get_tabpage(win)
  local state = self._tabs[tab]
  if not state then
    return
  end
  state.main = win
  self:apply(tab, true)
end

-- Returns the names of all layouts, in the order next() cycles through them
-- @return string[] Layout names
function Manager:names()
  return vim.list_extend({}, self._order)
end

return {
  new = Manager.new,
  Manager = Manager,
}
