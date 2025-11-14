local resize_actions = require('viewport.actions.resize')
local swap_actions = require('viewport.actions.swap')
local focus_actions = require('viewport.actions.focus')
local select_actions = require('viewport.actions.select')
local zoom_actions = require('viewport.actions.zoom')

local actions = {}

actions = vim.tbl_extend("error",
  resize_actions,
  swap_actions,
  focus_actions,
  select_actions,
  zoom_actions
)

return actions
