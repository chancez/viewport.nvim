local window = require('viewport.window')
local focus = require('viewport.actions.focus')
local pick = require('viewport.pick')
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
function swap_actions.swap_above(_, _)
  if swap_window_direction("up") then
    focus.focus_above()
  end
end

-- Swaps the current window with the one below and focuses it
function swap_actions.swap_below(_, _)
  if swap_window_direction("down") then
    focus.focus_below()
  end
end

-- Swaps the current window with the one to the left and focuses it
function swap_actions.swap_left(_, _)
  if swap_window_direction("left") then
    focus.focus_left()
  end
end

-- Swaps the current window with the one to the right and focuses it
function swap_actions.swap_right(_, _)
  if swap_window_direction("right") then
    focus.focus_right()
  end
end

-- Picks another window from the current tabpage and swaps it with the current
-- window.
-- @param opts PickWindowOpts|nil Options for picking the window
function swap_actions.swap_select(_, opts)
  local current_win = window.new()
  local other_win = pick.window(vim.tbl_extend('keep', {
    -- Don't allow selecting the window being swapped
    should_exclude_window = function(win_id)
      return win_id == current_win.id
    end,
  }, opts or {}))
  if other_win then
    current_win:swap(other_win)
  end
end

return action.from_module(swap_actions)
