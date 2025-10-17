local window = require('viewport.window')

local focus_actions = {}

-- Focuses a window in the specified direction
-- @param direction string The direction to focus ("up", "down", "left", "right")
-- @return boolean True if a window was found and focused, false otherwise
local function focus_window(direction)
  local current_window = window.new()
  local neighbor = current_window:neighbor(direction)
  if neighbor then
    neighbor:focus()
    return true
  end
  return false
end

-- Focuses the window above the current one
function focus_actions.focus_above()
  focus_window("up")
end

-- Focuses the window below the current one
function focus_actions.focus_below()
  focus_window("down")
end

-- Focuses the window to the left of the current one
function focus_actions.focus_left()
  focus_window("left")
end

-- Focuses the window to the right of the current one
function focus_actions.focus_right()
  focus_window("right")
end

return focus_actions
