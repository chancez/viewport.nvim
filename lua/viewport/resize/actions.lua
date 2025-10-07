local window = require('viewport.window')

local actions = {}

local resize = function(direction, amount)
  local win = window.new()
  win:resize(direction, amount or 1)
end

local relative_resize = function(direction, amount)
  local win = window.new()
  win:relative_resize(direction, amount)
end

function actions.resize_up(opts)
  opts = opts or {}
  resize("up", opts.amount or 1)
end

function actions.resize_down(opts)
  opts = opts or {}
  resize("down", opts.amount or 1)
end

function actions.resize_left(opts)
  opts = opts or {}
  resize("left", opts.amount or 1)
end

function actions.resize_right(opts)
  opts = opts or {}
  resize("right", opts.amount or 1)
end

function actions.relative_resize_up(opts)
  opts = opts or {}
  relative_resize("up", opts.amount or 1)
end

function actions.relative_resize_down(opts)
  opts = opts or {}
  relative_resize("down", opts.amount or 1)
end

function actions.relative_resize_left(opts)
  opts = opts or {}
  relative_resize("left", opts.amount or 1)
end

function actions.relative_resize_right(opts)
  opts = opts or {}
  relative_resize("right", opts.amount or 1)
end

return actions
