-- @class NavigateConfig
-- @field mappings table Table of key mappings for navigation actions
--
-- @class ResizeMappings
-- @field preset string|nil Preset configuration ('absolute' or 'relative')

-- @class ResizeConfig
-- @field resize_amount number The default amount to resize by
-- @field mappings table|ResizeMappings Configuration for key mappings

-- @class Config
-- @field resize_mode ResizeConfig Configuration for resize mode
-- @field navigate_mode NavigateConfig Configuration for navigation mode
