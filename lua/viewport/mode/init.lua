local keymap = require('viewport.mode.keymap')

local M = {}

-- @class Mode
-- @field active boolean Whether the mode is currently active
-- @field keymap_manager KeymapManager The keymap manager for buffer-local keymaps
-- @field config ModeConfig The mode configuration
local Mode = {}
Mode.__index = Mode

-- @class ModeConfig
-- @field mappings table Table of key mappings for the mode
-- @field mapping_opts table Options to pass to vim.keymap.set
-- @field pre_start function Function called before mode starts
-- @field post_start function Function called after mode starts
-- @field pre_stop function Function called before mode stops
-- @field post_stop function Function called after mode stops

-- Default configuration for modes
-- @type ModeConfig
local default_mode_opts = {
  mappings = {
    ['<Esc>'] = 'stop',
  },
  mapping_opts = {},
  pre_start = function() end,
  post_start = function() end,
  pre_stop = function() end,
  post_stop = function() end,
}

-- Creates a new Mode instance
-- @param config ModeConfig|nil Configuration for the mode
-- @return Mode A new Mode instance
function Mode.new(config)
  local self = setmetatable({}, Mode)
  self.active = false
  self.keymap_manager = keymap.new()
  self.config = vim.tbl_deep_extend('force', default_mode_opts, config or {})
  -- validate mappings
  vim.validate('mappings', self.config.mappings, 'table')
  for lhs, rhs in pairs(self.config.mappings) do
    vim.validate("lhs", lhs, 'string')
    vim.validate("rhs", rhs, { 'function', 'string' })
  end
  return self
end

-- Starts the mode, activating key mappings and calling lifecycle hooks
-- @param opts table|nil Options to pass to action functions
function Mode:start(opts)
  if self.active then
    return
  end
  self.active = true
  self.config.pre_start()
  self.keymap_manager:save('n') -- TODO: Support other modes.

  local mapping_opts = vim.tbl_extend('keep', { silent = true }, self.config.mapping_opts)
  local it = vim.iter(self.config.mappings)
  it:each(function(lhs, action)
    -- TODO: Support other modes.
    self.keymap_manager:set('n', lhs, function()
      if action == 'stop' then
        self:stop()
      else
        -- Allow actions to stop the mode by returning true
        if action(opts) == true then
          self:stop()
        end
      end
    end, mapping_opts)
  end)

  self.config.post_start()
end

-- Stops the mode, restoring original key mappings and calling lifecycle hooks
function Mode:stop()
  self.config.pre_stop()
  -- Restore all mappings using the keymap manager
  self.keymap_manager:restore('n')
  self.config.post_stop()
  self.active = false
end

M.Mode = Mode

-- Creates a new Mode instance
-- @param config ModeConfig|nil Configuration for the mode
-- @return Mode A new Mode instance
M.new = function(config)
  return Mode.new(config)
end

return M
