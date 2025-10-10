local actions = require('viewport.resize.actions')
local mode = require('viewport.mode')

local M = {}

M.actions = actions

local preset_mappings = {
  absolute = {
    ['k'] = actions.resize_up,
    ['j'] = actions.resize_down,
    ['h'] = actions.resize_left,
    ['l'] = actions.resize_right,
    ['<Esc>'] = 'stop',
  },
  relative = {
    ['k'] = actions.relative_resize_up,
    ['j'] = actions.relative_resize_down,
    ['h'] = actions.relative_resize_left,
    ['l'] = actions.relative_resize_right,
    ['<Esc>'] = 'stop',
  },
}

local default_config = {
  resize_amount = 1,
  mappings = {
    preset = 'absolute', -- 'absolute' or 'relative'
  },
}

local config = {}
local resize_mode = nil

M.setup = function(input_cfg)
  config = vim.tbl_deep_extend('force', default_config, input_cfg or {})
  --
  -- Deep copy because we're going to mutate the values potentially
  local mappings = vim.deepcopy(config.mappings)
  if mappings.preset then
    local preset = preset_mappings[config.mappings.preset]
    if not preset then
      error("Invalid preset: " .. tostring(config.mappings.preset))
    end
    -- Delete the preset key so it isnt treated as a mapping itself
    mappings.preset = nil
    mappings = vim.tbl_extend('force', preset, mappings)
  end

  resize_mode = mode.new({
    mappings = mappings,
  })
end

M.start = function()
  if resize_mode == nil then
    error("Resize mode not initialized. Please call setup() first.")
  end
  resize_mode:start({
    amount = config.resize_amount,
  })
end

return M
