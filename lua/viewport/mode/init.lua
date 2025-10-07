local keymap = require('viewport.mode.keymap')

local M = {}

local Mode = {}
Mode.__index = Mode

function Mode:new(keymaps)
  local instance = setmetatable({}, Mode)
  instance.active = false
  instance.current_mappings = {}
  instance.keymaps = keymaps or {}
  -- Check for a 'stop mapping', if not present add <Esc> as default
  if not vim.tbl_contains(vim.tbl_values(instance.keymaps), 'stop') then
    instance.keymaps['<Esc>'] = 'stop'
  end
  return instance
end

function Mode:start(opts)
  if self.active then
    return
  end
  self.active = true

  local mapping_opts = { silent = true }
  local it = vim.iter(self.keymaps)
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

function Mode:stop()
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

M.Mode = Mode
M.new = function(keymaps)
  return Mode:new(keymaps)
end

return M
