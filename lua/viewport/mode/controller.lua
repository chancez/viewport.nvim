-- Tracks a set of named modes and which one is active. At most one mode is
-- active at a time: starting a mode stops the active one. Modes know nothing
-- about the controller, they only report back through the on_stop callback
-- passed to start().
local Controller = {}
Controller.__index = Controller

-- @class ControllerOpts
-- @field on_change function|nil Called with the active mode name, or nil, whenever it changes

-- Creates a new controller
-- @param opts ControllerOpts|nil Options for the controller
-- @return Controller A new controller
function Controller.new(opts)
  opts = opts or {}
  vim.validate("on_change", opts.on_change, { 'function', 'nil' })
  local self = setmetatable({}, Controller)
  self._modes = {}
  self._active = nil
  self._on_change = opts.on_change or function(_) end
  return self
end

-- Registers a mode instance
-- @param name string Mode name
-- @param mode_instance Mode The mode instance to register
function Controller:register(name, mode_instance)
  self._modes[name] = mode_instance
end

-- Gets a registered mode instance
-- @param name string Mode name
-- @return Mode|nil The registered mode instance or nil
function Controller:get(name)
  return self._modes[name]
end

-- Returns the name of the active mode, if any
-- @return string|nil The active mode name
function Controller:active()
  return self._active and self._active.name
end

-- Starts a registered mode, stopping the active one first. Does nothing if
-- the mode is already active.
-- @param name string Mode name
-- @error Throws an error if mode is not registered
function Controller:start(name)
  local mode_instance = self:get(name)
  if mode_instance == nil then
    error(string.format("%s mode not initialized. Please call setup() first.", name))
  end
  if self:active() == name then
    return
  end
  self:stop()

  local active = { name = name, mode = mode_instance }
  self._active = active
  mode_instance:start(function()
    -- Ignore a stale callback if another mode became active in the meantime
    if self._active == active then
      self._active = nil
      self._on_change(nil)
    end
  end)
  self._on_change(name)
end

-- Stops the active mode, if any
function Controller:stop()
  if self._active then
    self._active.mode:stop()
  end
end

-- Stops the mode if it is active, otherwise starts it
-- @param name string Mode name
function Controller:toggle(name)
  if self:active() == name then
    self:stop()
  else
    self:start(name)
  end
end

return {
  new = Controller.new,
  Controller = Controller,
}
