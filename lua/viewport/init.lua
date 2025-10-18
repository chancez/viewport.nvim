local default_config = require('viewport.config')
local modes = require('viewport.modes')
local mode = require('viewport.mode')
local presets = require('viewport.presets')

local M = {}

-- Creates a new mode instance with the given name and options
-- @param name string Name of the mode ('resize' or 'navigate')
-- @param opts table Configuration options for the mode
-- @return Mode New mode instance
local function new_mode(name, mappings, action_opts)
  mappings = vim.deepcopy(mappings)
  if mappings.preset then
    local preset = presets.get(name, mappings.preset)
    -- Delete the preset key so it isnt treated as a mapping itself
    mappings.preset = nil
    mappings = vim.tbl_extend('force', preset, mappings)
  end

  local mode_opts = {
    mappings = mappings,
    action_opts = action_opts or {},
  }

  local new_m = mode.new(mode_opts)
  modes.register(name, new_m)
  return new_m
end

-- Sets up the viewport plugin with the given options
-- @param opts Config|nil Configuration options
function M.setup(opts)
  opts = vim.tbl_deep_extend('force', default_config, opts or {})
  -- Create and register modes
  new_mode('resize', opts.resize_mode.mappings, {
    resize_amount = opts.resize_mode.resize_amount,
  })
  new_mode('navigate', opts.navigate_mode.mappings)
end

function M.start_resize_mode()
  modes.start('resize')
end

function M.start_navigate_mode()
  modes.start('navigate')
end

return M
