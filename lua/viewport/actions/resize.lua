local window = require('viewport.window')
local action = require('viewport.action')

local resize_actions = {}

-- @class ResizeActionOpts
-- @field amount number The amount to resize by

-- Resizes a window in the specified direction
-- @param direction string The direction to resize ("up", "down", "left", "right")
-- @param amount number The amount to resize by
local resize = function(direction, amount)
  local win = window.new()
  win:resize(direction, amount or 1)
end

-- Resizes a window relative to its neighbors
-- @param direction string The direction to resize ("up", "down", "left", "right")
-- @param amount number The amount to resize by
local relative_resize = function(direction, amount)
  local win = window.new()
  win:relative_resize(direction, amount)
end

-- Resizes the current window upward
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.resize_up(opts)
  opts = opts or {}
  resize("up", opts.resize_amount or 1)
end

-- Resizes the current window downward
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.resize_down(opts)
  opts = opts or {}
  resize("down", opts.resize_amount or 1)
end

-- Resizes the current window leftward
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.resize_left(opts)
  opts = opts or {}
  resize("left", opts.resize_amount or 1)
end

-- Resizes the current window rightward
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.resize_right(opts)
  opts = opts or {}
  resize("right", opts.resize_amount or 1)
end

-- Resizes the current window upward relative to neighbors
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.relative_resize_up(opts)
  opts = opts or {}
  relative_resize("up", opts.resize_amount or 1)
end

-- Resizes the current window downward relative to neighbors
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.relative_resize_down(opts)
  opts = opts or {}
  relative_resize("down", opts.resize_amount or 1)
end

-- Resizes the current window leftward relative to neighbors
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.relative_resize_left(opts)
  opts = opts or {}
  relative_resize("left", opts.resize_amount or 1)
end

-- Resizes the current window rightward relative to neighbors
-- @param opts ResizeActionOpts|nil Options containing resize amount
function resize_actions.relative_resize_right(opts)
  opts = opts or {}
  relative_resize("right", opts.resize_amount or 1)
end

-- Convert all the functions into actions with their descriptions based on the function names
return action.from_module(resize_actions)
