local default_config = require('viewport.config')
local controller = require('viewport.mode.controller')
local mode = require('viewport.mode')
local presets = require('viewport.presets')
local pick = require('viewport.pick')
local swap_actions = require('viewport.actions.swap')
local extend = require('viewport.extend')

local M = {}

-- Autocmd pattern emitted when the active mode changes
M.mode_change_autocmd = "ViewportModeChange"

-- The controller tracking viewport's modes. The active mode name is mirrored
-- to vim.g.viewport_active_mode for status lines.
M.controller = controller.new({
  on_change = function(name)
    vim.g.viewport_active_mode = name
    vim.api.nvim_exec_autocmds("User", {
      pattern = M.mode_change_autocmd,
      data = { mode = name },
    })
  end,
})

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
    -- User defined mappings override preset mappings
    mappings = extend.tbl_deep_extend('force', preset, mappings)
  end

  mode_opts.mappings = mappings

  local new_m = mode.new(mode_opts)
  M.controller:register(name, new_m)
  return new_m
end

-- Sets up the viewport plugin with the given options
-- @param opts Config|nil Configuration options
function M.setup(opts)
  opts = extend.tbl_deep_extend('force', default_config, opts or {})
  M.config = opts
  -- Create and register modes
  new_mode('resize', {
    mappings = opts.resize_mode.mappings,
    action_opts = {
      resize_amount = opts.resize_mode.resize_amount,
    },
    stop_after_action = false,
    display_mappings = opts.resize_mode.display_mappings,
  })

  new_mode('navigate', {
    mappings = opts.navigate_mode.mappings,
    stop_after_action = false,
    display_mappings = opts.navigate_mode.display_mappings,
  })
end

function M.start_resize_mode()
  M.controller:start('resize')
end

function M.start_navigate_mode()
  M.controller:start('navigate')
end

-- Stops the mode if it is active, otherwise starts it
-- @param name string Mode name ('resize' or 'navigate')
function M.toggle_mode(name)
  M.controller:toggle(name)
end

-- Stops the active mode, if any
function M.stop_mode()
  M.controller:stop()
end

-- Picks a window, then an action from select_mode.choices to run on it
function M.start_select_mode()
  pick.window_action(M.config.select_mode.choices)
end

-- Picks a window to swap with the current window
function M.start_swap_mode()
  swap_actions.swap_select()
end

return M
