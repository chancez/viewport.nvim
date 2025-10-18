local default_config = require('viewport.config')
local modes = require('viewport.modes')
local mode = require('viewport.mode')
local presets = require('viewport.presets')
local select_actions = require('viewport.actions.select')

local M = {}

-- Creates a new mode instance with the given name and options
-- @param name string Name of the mode ('resize' or 'navigate')
-- @param opts table Configuration options for the mode
-- @return Mode New mode instance
local function new_mode(name, mode_opts)
  mode_opts = vim.deepcopy(mode_opts)
  local mappings = vim.deepcopy(mode_opts.mappings or {})
  if mappings.preset then
    local preset = presets.get(name, mappings.preset)
    -- Delete the preset key so it isnt treated as a mapping itself
    mappings.preset = nil
    mappings = vim.tbl_extend('force', preset, mappings)
  end
  mode_opts.mappings = mappings

  local new_m = mode.new(mode_opts)
  modes.register(name, new_m)
  return new_m
end

-- Sets up the viewport plugin with the given options
-- @param opts Config|nil Configuration options
function M.setup(opts)
  opts = vim.tbl_deep_extend('force', default_config, opts or {})
  -- Create and register modes
  new_mode('resize', {
    mappings = opts.resize_mode.mappings,
    action_opts = {
      resize_amount = opts.resize_mode.resize_amount,
    },
    stop_after_action = false,
  })
  new_mode('navigate', {
    mappings = opts.navigate_mode.mappings,
    stop_after_action = false,
  })

  modes.register('select', select_actions.new_window_selector_mode(
    function(win)
      select_actions.new_window_choice_picker(win, opts.select_mode.choices)
    end
  ))

  modes.register('swap', select_actions.new_swap_mode())
end

function M.start_resize_mode()
  modes.start('resize')
end

function M.start_navigate_mode()
  modes.start('navigate')
end

function M.start_select_mode()
  modes.start('select')
end

function M.start_swap_mode()
  modes.start('swap')
end

return M
