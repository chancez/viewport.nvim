local keymap = require('viewport.mode.keymap')

local M = {}

local Mode = {}
Mode.__index = Mode

function Mode.new(config)
  config = config or {}
  local self = setmetatable({}, Mode)
  self.active = false
  self.current_mappings = {}
  self.config = vim.tbl_extend('keep', config, {
    mappings = {
      ['<Esc>'] = 'stop',
    },
    mapping_opts = {},
    pre_start = function() end,
    post_start = function() end,
    pre_stop = function() end,
    post_stop = function() end,
  })
  return self
end

function Mode:start(opts)
  if self.active then
    return
  end
  self.active = true
  self.config.pre_start()

  local mapping_opts = vim.tbl_extend('keep', { silent = true }, self.config.mapping_opts)
  local it = vim.iter(self.config.mappings)
  self.current_mappings = it:map(function(lhs, action)
    return {
      lhs = lhs,
      -- map returns the existing mapping so we can restore it later
      old = keymap.set('n', lhs, function()
        if action == 'stop' then
          self:stop()
        else
          -- Allow actions to stop the mode by returning true
          if action(opts) == true then
            self:stop()
          end
        end
      end, mapping_opts),
    }
  end):totable()

  self.config.post_start()
end

function Mode:stop()
  self.config.pre_stop()
  -- restore old mappings
  for _, mapping in ipairs(self.current_mappings) do
    if next(mapping.old) ~= nil then
      vim.fn.mapset(mapping.old)
    else
      -- Mapping was empty so delete the new temporary mapping
      vim.keymap.del('n', mapping.lhs)
    end
  end
  self.config.post_stop()
  self.current_mappings = {}
  self.active = false
end

M.Mode = Mode
M.new = function(config)
  return Mode.new(config)
end

return M
