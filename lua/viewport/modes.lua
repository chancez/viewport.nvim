-- Central registry for mode instances
-- This module breaks the circular dependency between modes and presets
local registry = {}

local M = {}

local mode_change_autocmd = "ViewportModeChange"

-- Sets the active mode and emits an autocmd
-- @param name string|nil Mode name or nil if no active mode
local function set_active_mode(name)
  -- Set the global variable for external plugins to query
  vim.g.viewport_active_mode = name
  -- Emit an autocmd for mode change
  vim.api.nvim_exec_autocmds("User", {
    pattern = mode_change_autocmd,
    data = { mode = name },
  })
end

-- Autocmd event name emitted on mode change
M.mode_change_autocmd = mode_change_autocmd

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
  --
  -- Set vim.g.viewport_active_mode for external plugins to query
  local old_post_start = mode_instance.config.post_start
  local old_post_stop = mode_instance.config.post_stop
  mode_instance.config.post_start = function(self)
    set_active_mode(name)
    old_post_start(self)
  end
  mode_instance.config.post_stop = function(self)
    set_active_mode(nil)
    old_post_stop(self)
  end

  mode_instance:start()
end

-- Returns the currently active mode if any
-- @return Mode|nil The active mode instance or nil
function M.get_active_mode()
  local active_mode_name = vim.g.viewport_active_mode
  if active_mode_name then
    return registry[active_mode_name]
  end
  return nil
end

return M
