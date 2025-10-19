local M = {}

-- @class Action @field _func function The function to execute for the action
-- @field _desc string Description of the action
local Action = {}
Action.__index = Action

-- Creates a new Action instance
-- @param func function The function to execute for the action
-- @param desc string Description of the action
function Action.new(func, desc)
  vim.validate("func", func, 'function')
  vim.validate("desc", desc, 'string')

  local self = setmetatable({}, Action)
  self._func = func
  self._desc = desc
  return self
end

-- Executes the action
function Action:execute(...)
  return self._func(...)
end

-- Gets the description of the action
function Action:description()
  return self._desc
end

-- Call the action instance like a function
function Action.__call(self, ...)
  return self._func(...)
end

M.Action = Action
M.new = Action.new

-- Convert a module of functions into Action instances
function M.from_module(module)
  local actions = {}
  for name, func in pairs(module) do
    if type(func) == 'function' then
      local desc = string.format("Action: %s", name)
      local act = Action.new(func, desc)
      actions[name] = act
    else
      actions[name] = func
    end
  end
  return actions
end

return M
