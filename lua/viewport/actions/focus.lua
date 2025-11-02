local window = require('viewport.window')
local action = require('viewport.action')

local focus_actions = {}

-- Focuses the window above the current one
function focus_actions.focus_above(_, _)
  window.new():focus_direction("up")
end

-- Focuses the window below the current one
function focus_actions.focus_below(_, _)
  window.new():focus_direction("down")
end

-- Focuses the window to the left of the current one
function focus_actions.focus_left(_, _)
  window.new():focus_direction("left")
end

-- Focuses the window to the right of the current one
function focus_actions.focus_right(_, _)
  window.new():focus_direction("right")
end

return action.from_module(focus_actions)
