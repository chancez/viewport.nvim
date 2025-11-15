-- Central registry for mode instances
local registry = {
  _modes = {},
  -- Autocmd event name emitted on mode change
  mode_change_autocmd = "ViewportModeChange"
}


local function emit_mode_changed(name)
  -- Emit an autocmd for mode change
  vim.api.nvim_exec_autocmds("User", {
    pattern = registry.mode_change_autocmd,
    data = { mode = name },
  })
end

-- Sets the active mode and emits an autocmd
-- @param name string|nil Mode name or nil if no active mode
local function set_active_mode(name)
  -- Check if mode is already set, and store previous mode
  -- Set the global variable for external plugins to query
  vim.g.viewport_active_mode = name
  emit_mode_changed(name)
end

-- Clears the active mode and emits an autocmd
local function clear_active_mode()
  vim.g.viewport_active_mode = nil
  emit_mode_changed(nil)
end

-- Registers a mode instance
-- @param name string Mode name
-- @param mode_instance Mode The mode instance to register
function registry.register(name, mode_instance)
  registry._modes[name] = mode_instance
end

-- Gets a registered mode instance
-- @param name string Mode name
-- @return Mode|nil The registered mode instance or nil
function registry.get(name)
  return registry._modes[name]
end

-- Starts a registered mode
-- @param name string Mode name
-- @error Throws an error if mode is not registered
function registry.start(name)
  local mode_instance = registry.get(name)
  if mode_instance == nil then
    error(string.format("%s mode not initialized. Please call setup() first.", name))
  end

  -- Stop any active mode
  local prev_mode = vim.g.viewport_active_mode
  if prev_mode then
    vim.g.viewport_previous_mode = prev_mode
    registry.get_active_mode():stop()
  end

  -- Set vim.g.viewport_active_mode for external plugins to query
  local old_post_start = mode_instance.config.post_start
  local old_post_stop = mode_instance.config.post_stop
  mode_instance.config.post_start = function(self)
    set_active_mode(name)
    old_post_start(self)
  end
  mode_instance.config.post_stop = function(self)
    -- Restore previous mode if any
    if prev_mode then
      clear_active_mode()
      registry.start(prev_mode)
    else
      clear_active_mode()
    end
    old_post_stop(self)
  end

  mode_instance:start()
end

-- Returns the currently active mode if any
-- @return Mode|nil The active mode instance or nil
function registry.get_active_mode()
  local active_mode_name = vim.g.viewport_active_mode
  if active_mode_name then
    return registry.get(active_mode_name)
  end
  return nil
end

return registry
