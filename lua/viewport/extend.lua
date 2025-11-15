local M = {}

--- We only merge empty tables or tables that are not list-like (indexed by consecutive integers
--- starting from 1)
function M.can_merge(v)
  return type(v) == 'table' and (vim.tbl_isempty(v) or not vim.islist(v))
end

-- Merges two tables according to the specified behavior.
-- @param behavior 'error'|'keep'|'force'|fun(src:any?, other:any): any
-- @param recursive boolean
-- @param src table
-- @param other table
function M.merge(behavior, recursive, src, other)
  local ret = vim.deepcopy(src)
  if not M.can_merge(other) then
    return ret
  end

  for k, v in pairs(other) do
    if type(behavior) == 'function' then
      ret[k] = behavior(ret[k], v)
    elseif recursive and M.can_merge(v) and M.can_merge(ret[k]) then
      ret[k] = M.merge(behavior, recursive, ret[k], v)
    elseif behavior ~= 'force' and ret[k] ~= nil then
      if behavior == 'error' then
        error('key found in more than one map: ' .. k)
      end        -- Else behavior is "keep".
    else
      ret[k] = v -- Behavior is "force"
    end
  end
  return ret
end

-- Merges two or more tables according to the specified behavior.
local function merge_multi(behavior, deep_extend, ...)
  -- Start with a deep copy of the first table
  local ret = vim.deepcopy(select(1, ...)) --[[@as table<any,any>]]
  -- Merge each subsequent table into ret, starting with the second table
  for i = 2, select('#', ...) do
    local tbl = select(i, ...) --[[@as table<any,any>]]
    if tbl then
      ret = M.merge(behavior, deep_extend, ret, tbl)
    end
  end

  return ret
end

-- Helper function to validate arguments and call merge_multi
local function tbl_merge(behavior, deep_extend, ...)
  if
      behavior ~= 'error'
      and behavior ~= 'keep'
      and behavior ~= 'force'
      and type(behavior) ~= 'function'
  then
    error('invalid "behavior": ' .. tostring(behavior))
  end

  local nargs = select('#', ...)

  if nargs < 2 then
    error(('wrong number of arguments (given %d, expected at least 3)'):format(1 + nargs))
  end

  for i = 1, nargs do
    vim.validate('after the second argument', select(i, ...), 'table')
  end

  return merge_multi(behavior, deep_extend, ...)
end

--- Merges two or more tables.
---
---@see |extend()|
---
---@param behavior 'error'|'keep'|'force'|fun(src:any?, other:any): any Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---      - If a function, it receives the previous value in the currently merged table (if present), and the new value.
---@param ... table Two or more tables
---@return table : Merged table
function M.tbl_extend(behavior, ...)
  return tbl_merge(behavior, false, ...)
end

--- Merges recursively two or more tables.
---
--- Only values that are empty tables or tables that are not |lua-list|s (indexed by consecutive
--- integers starting from 1) are merged recursively. This is useful for merging nested tables
--- like default and user configurations where lists should be treated as literals (i.e., are
--- overwritten instead of merged).
---
---@see |vim.tbl_extend()|
---
---@generic T1: table
---@generic T2: table
---@param behavior 'error'|'keep'|'force'|fun(src:any?, other:any): any Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---      - If a function, it receives the previous value in the currently merged table (if present), and the new value.
---@param ... T2 Two or more tables
---@return T1|T2 (table) Merged table
function M.tbl_deep_extend(behavior, ...)
  return tbl_merge(behavior, true, ...)
end

return M
