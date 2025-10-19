local window = require('viewport.window')
local focus = require('viewport.actions.focus')
local action = require('viewport.action')

local swap_actions = {}

-- Swaps the current window with a window in the specified direction
-- @param direction string The direction to swap with
-- @return boolean True if the swap was successful, false otherwise
local function swap_window_direction(direction)
  local current_window = window.new()
  return current_window:swap_direction(direction)
end

-- Swaps the current window with the one above and focuses it
function swap_actions.swap_above()
  if swap_window_direction("up") then
    focus.focus_above()
  end
end

-- Swaps the current window with the one below and focuses it
function swap_actions.swap_below()
  if swap_window_direction("down") then
    focus.focus_below()
  end
end

-- Swaps the current window with the one to the left and focuses it
function swap_actions.swap_left()
  if swap_window_direction("left") then
    focus.focus_left()
  end
end

-- Swaps the current window with the one to the right and focuses it
function swap_actions.swap_right()
  if swap_window_direction("right") then
    focus.focus_right()
  end
end

return action.from_module(swap_actions)
