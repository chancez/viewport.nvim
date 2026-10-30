local action = require('viewport.action')

local layout_actions = {}

-- Makes the current window the main window of the current layout
function layout_actions.make_main(_, _)
  local layouts = require('viewport').layouts
  if layouts then
    layouts:make_main()
  end
end

-- Switches the current tabpage to the next layout
function layout_actions.next_layout(_, _)
  require('viewport').next_layout()
end

return action.from_module(layout_actions)
