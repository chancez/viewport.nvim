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
    i = {
      ['<Esc>'] = 'stop',
    },
    n = {
      ['<Esc>'] = 'stop',
    }
  },
  action_opts = {},
  mapping_opts = {},
  pre_start = function(_) end,
  post_start = function(_) end,
  pre_stop = function(_) end,
  post_stop = function(_) end,
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
  vim.validate("mappings", self.config.mappings, 'table')
  for mode, mappings in pairs(self.config.mappings) do
    vim.validate("mode", mode, 'string')
    for lhs, rhs in pairs(mappings) do
      vim.validate("lhs", lhs, 'string')
      vim.validate("rhs", rhs, { 'function', 'string' })
    end
  end
  return self
end

-- Starts the mode, activating key mappings and calling lifecycle hooks
function Mode:start()
  if self.active then
    return
  end
  self.active = true
  self.config.pre_start(self)

  local modes = vim.tbl_keys(self.config.mappings)
  self.keymap_manager:save(modes)

  local mapping_opts = vim.tbl_extend('keep', { silent = true }, self.config.mapping_opts)
  for mode, mappings in pairs(self.config.mappings) do
    for lhs, rhs in pairs(mappings) do
      self.keymap_manager:set(mode, lhs, function()
        if rhs == 'stop' then
          self:stop()
        else
          -- Allow actions to stop the mode by returning true
          if rhs(self.config.action_opts) == true then
            self:stop()
          end
        end
      end, mapping_opts)
    end
  end

  self.config.post_start(self)
end

-- Stops the mode, restoring original key mappings and calling lifecycle hooks
function Mode:stop()
  self.config.pre_stop(self)
  self.keymap_manager:restore()
  self.config.post_stop(self)
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
