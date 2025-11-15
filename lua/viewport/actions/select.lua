local modes = require('viewport.modes')
local action = require('viewport.action')

local select_actions = {}

-- Starts a mode to select a window from the current tabpage and focuses it
-- when selected.
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function select_actions.select_window(_, opts)
  modes.WindowSelectorMode.new(
    function(win)
      win:focus()
    end,
    opts or {}
  ):start()
end

return action.from_module(select_actions)
