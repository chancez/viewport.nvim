local actions = require('viewport.resize.actions')
local mode = require('viewport.mode')

local M = {}

M.actions = actions

local default_config = {
  resize_amount = 1,
  mappings = {
    ['k'] = actions.resize_up,
    ['j'] = actions.resize_down,
    ['h'] = actions.resize_left,
    ['l'] = actions.resize_right,
    ['<Esc>'] = 'stop',
  },
}

local config = {}
local resize_mode = nil

M.setup = function(input_cfg)
  config = vim.tbl_deep_extend('force', default_config, input_cfg or {})
  resize_mode = mode.new(config.mappings)
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
