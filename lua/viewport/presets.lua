local resize_actions = require('viewport.actions.resize')
local swap_actions = require('viewport.actions.swap')
local focus_actions = require('viewport.actions.focus')
local select_actions = require('viewport.actions.select')

local presets = {}

local preset_mappings = {
  resize = {
    absolute = {
      n = {
        ['k'] = resize_actions.resize_up,
        ['j'] = resize_actions.resize_down,
        ['h'] = resize_actions.resize_left,
        ['l'] = resize_actions.resize_right,
        ['<Esc>'] = 'stop',
      },
    },
    relative = {
      n = {
        ['k'] = resize_actions.relative_resize_up,
        ['j'] = resize_actions.relative_resize_down,
        ['h'] = resize_actions.relative_resize_left,
        ['l'] = resize_actions.relative_resize_right,
        ['<Esc>'] = 'stop',
      },
    },

  },
  navigate = {
    default = {
      n = {
        ['k'] = focus_actions.focus_above,
        ['j'] = focus_actions.focus_below,
        ['h'] = focus_actions.focus_left,
        ['l'] = focus_actions.focus_right,
        ['K'] = swap_actions.swap_above,
        ['J'] = swap_actions.swap_below,
        ['H'] = swap_actions.swap_left,
        ['L'] = swap_actions.swap_right,
        ['s'] = select_actions.select_window,
        ['<Esc>'] = 'stop',
      },
    },
  },
}

-- Retrieves a preset mapping for the given mode and name
-- @param mode string Mode name ('resize' or 'navigate')
-- @param name string Preset name
-- @return table Preset mapping table
function presets.get(mode, name)
  local preset = preset_mappings[mode][name]
  if not preset then
    error(string.format("Invalid preset: %s for mode %s", name, mode))
  end
  return preset
end

return presets
