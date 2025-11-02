local action = require('viewport.action')

local mode_actions = {}

function mode_actions.stop(mode_instance, _)
  mode_instance:stop()
end

function mode_actions.toggle_display_mappings(mode_instance, _)
  mode_instance:toggle_mappings_display()
end

return action.from_module(mode_actions)
-- return mode_actions
