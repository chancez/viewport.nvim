local pick = require('viewport.pick')
local action = require('viewport.action')

local select_actions = {}

-- Picks a window from the current tabpage and focuses it.
-- @param opts PickWindowOpts|nil Options for picking the window
-- @error Throws an error if there are more windows than available choices
function select_actions.select_window(_, opts)
  local win = pick.window(opts)
  if win then
    win:focus()
  end
end

return action.from_module(select_actions)
