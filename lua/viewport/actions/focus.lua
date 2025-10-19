local window = require('viewport.window')
local action = require('viewport.action')

local focus_actions = {}

-- Focuses the window above the current one
function focus_actions.focus_above()
  window.new():focus_direction("up")
end

-- Focuses the window below the current one
function focus_actions.focus_below()
  window.new():focus_direction("down")
end

-- Focuses the window to the left of the current one
function focus_actions.focus_left()
  window.new():focus_direction("left")
end

-- Focuses the window to the right of the current one
function focus_actions.focus_right()
  window.new():focus_direction("right")
end

return action.from_module(focus_actions)
