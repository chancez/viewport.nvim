local default_config = require('viewport.config')
local mode = require('viewport.mode')
local presets = require('viewport.presets')

local M = {}

local resize_mode = nil
local navigate_mode = nil

-- Sets up the resize mode with the given configuration
-- @param resize_config ResizeConfig|nil Configuration table to merge with defaults
local setup_resize_mode = function(resize_config)
  -- Deep copy because we're going to mutate the values potentially
  local mappings = vim.deepcopy(resize_config.mappings)
  if mappings.preset then
    local preset = presets.get('resize', mappings.preset)
    -- Delete the preset key so it isnt treated as a mapping itself
    mappings.preset = nil
    mappings = vim.tbl_extend('force', preset, mappings)
  end

  resize_mode = mode.new({
    mappings = mappings,
    amount = resize_config.resize_amount,
  })
end

-- Sets up the navigation mode with the given configuration
-- @param navigate_config NavigateConfig|nil Configuration table to merge with defaults
local setup_navigate_mode = function(navigate_config)
  -- Deep copy because we're going to mutate the values potentially
  local mappings = vim.deepcopy(navigate_config.mappings)
  if mappings.preset then
    local preset = presets.get('navigate', mappings.preset)
    -- Delete the preset key so it isnt treated as a mapping itself
    mappings.preset = nil
    mappings = vim.tbl_extend('force', preset, mappings)
  end
  navigate_mode = mode.new({
    mappings = mappings,
  })
end

-- Sets up the resize mode with the given configuration
-- @param opts ResizeConfig|nil Configuration table to merge with defaults
-- @error Throws an error if an invalid preset is specified
M.setup = function(opts)
  opts = vim.tbl_deep_extend('force', default_config, opts or {})
  setup_resize_mode(opts.resize_mode)
  setup_navigate_mode(opts.navigate_mode)
end

-- Starts resize mode
-- @error Throws an error if setup() has not been called first
M.start_resize_mode = function()
  if resize_mode == nil then
    error("Resize mode not initialized. Please call setup() first.")
  end
  resize_mode:start()
end

-- Starts the navigation mode
-- @error Throws an error if setup() has not been called first
M.start_navigate_mode = function()
  if navigate_mode == nil then
    error("navigate mode not initialized. Please call setup() first.")
  end
  navigate_mode:start()
end

return M
