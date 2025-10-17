local window = require('viewport.window')

local move_actions = {}

-- Moves the current window in the specified direction
-- @param direction string The direction to move the window
local function move_window(direction)
  local current_window = window.new()
  -- TODO: Do we need to check if the move is valid?
  current_window:move(direction)
end

-- Moves the current window up
function move_actions.move_up()
  move_window("up")
end

-- Moves the current window down
function move_actions.move_down()
  move_window("down")
end

-- Moves the current window left
function move_actions.move_left()
  move_window("left")
end

-- Moves the current window right
function move_actions.move_right()
  move_window("right")
end

return move_actions
