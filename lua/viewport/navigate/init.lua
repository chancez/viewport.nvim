local actions = require('viewport.navigate.actions')
local mode = require('viewport.mode')

local M = {}

M.actions = actions

local default_config = {
  mappings = {
    ['k'] = actions.focus_above,
    ['j'] = actions.focus_below,
    ['h'] = actions.focus_left,
    ['l'] = actions.focus_right,
    ['K'] = actions.swap_above,
    ['J'] = actions.swap_below,
    ['H'] = actions.swap_left,
    ['L'] = actions.swap_right,
    ['s'] = actions.select_mode,
    ['<Esc>'] = 'stop',
  },
}

local config = {}
local navigate_mode = nil

M.setup = function(input_cfg)
  config = vim.tbl_deep_extend('force', default_config, input_cfg or {})
  navigate_mode = mode.new({
    mappings = config.mappings,
  })
end

M.start = function()
  if navigate_mode == nil then
    error("select mode not initialized. Please call setup() first.")
  end
  navigate_mode:start({})
end

return M
