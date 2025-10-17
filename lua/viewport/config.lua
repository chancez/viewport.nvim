-- Default configuration for the viewport plugin
-- @type Config
local default_config = {}

default_config.resize_mode = {
  resize_amount = 1,
  mappings = {
    preset = 'absolute', -- 'absolute' or 'relative'
  },
}

default_config.navigate_mode = {
  mappings = {
    preset = 'default',
  }
}

return default_config
