-- Central registry for mode instances
-- This module breaks the circular dependency between modes and presets
local registry = {}

local M = {}

-- Registers a mode instance
-- @param name string Mode name
-- @param mode_instance Mode The mode instance to register
function M.register(name, mode_instance)
  registry[name] = mode_instance
end

-- Gets a registered mode instance
-- @param name string Mode name
-- @return Mode|nil The registered mode instance or nil
function M.get(name)
  return registry[name]
end

-- Starts a registered mode
-- @param name string Mode name
-- @error Throws an error if mode is not registered
function M.start(name)
  local mode_instance = registry[name]
  if mode_instance == nil then
    error(string.format("%s mode not initialized. Please call setup() first.", name))
  end
  mode_instance:start()
end

return M
