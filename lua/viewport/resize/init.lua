local actions = require('viewport.resize.actions')
local keymap = require('viewport.resize.keymap')

local M = {}

M.actions = actions

local default_config = {
  resize_amount = 1,
  mappings = {
    ['k'] = actions.resize_up,
    ['j'] = actions.resize_down,
    ['h'] = actions.resize_left,
    ['l'] = actions.resize_right,
    ['<Esc>'] = 'stop',
  },
}

local Resizer = {}
Resizer.__index = Resizer

function Resizer:new(cfg)
  local instance = setmetatable({}, Resizer)
  instance.active = false
  instance.current_mappings = {}
  instance.cfg = vim.tbl_deep_extend('force', default_config, cfg)
  return instance
end

function Resizer:start()
  if self.active then
    return
  end
  self.active = true

  -- TODO Move this
  local opts = {
    resize_amount = self.cfg.resize_amount,
  }

  local mapping_opts = { silent = true }
  local it = vim.iter(self.cfg.mappings)
  self.current_mappings = it:map(function(lhs, action)
    return {
      lhs = lhs,
      -- map returns the existing mapping so we can restore it later
      old = keymap.set('n', lhs, function()
        if action == 'stop' then
          self:stop()
        else
          action(opts)
        end
      end, mapping_opts),
    }
  end):totable()
end

function Resizer:stop()
  -- restore old mappings
  for _, mapping in ipairs(self.current_mappings) do
    if next(mapping.old) ~= nil then
      vim.fn.mapset(mapping.old)
    else
      -- Mapping was empty so delete the new temporary mapping
      vim.keymap.del('n', mapping.lhs)
    end
  end
  self.current_mappings = {}
  self.active = false
end

M.Resizer = Resizer

local default_instance = nil

M.setup = function(cfg)
  if default_instance == nil then
    default_instance = Resizer:new(cfg)
  end
end

M.start_resizer = function()
  if default_instance == nil then
    vim.notify("Viewport Resize not setup. Call require('viewport.resize').setup() first.", vim.log.levels.WARN)
    return
  end
  default_instance:start()
end

return M
