local window = require('viewport.window')

-- Arrange functions take a list of window ids, main window first, and move
-- them into a layout. They only move the windows given, so windows left out
-- (sidebars, quickfix, etc.) stay where they are.
local arrange = {}

-- @class ArrangeOpts
-- @field main_ratio number Fraction of the width (tall) or height (fat) given to the main window

-- Places each window from wins[from] on in direction of the window before it
local function chain(wins, direction, from)
  for i = from, #wins do
    window.new(wins[i]):place(direction, wins[i - 1])
  end
end

-- Equalizes window sizes in the tabpage containing win
local function equalize(win)
  vim.api.nvim_win_call(win, function()
    vim.cmd('wincmd =')
  end)
end

-- All windows side by side in one row
-- @param wins number[] Window ids, main window first
function arrange.horizontal(wins)
  chain(wins, 'right', 2)
  equalize(wins[1])
end

-- All windows stacked in one column
-- @param wins number[] Window ids, main window first
function arrange.vertical(wins)
  chain(wins, 'down', 2)
  equalize(wins[1])
end

-- Main window on the left, the rest stacked on the right
-- @param wins number[] Window ids, main window first
-- @param opts ArrangeOpts
function arrange.tall(wins, opts)
  if #wins < 2 then
    return
  end
  window.new(wins[2]):place('right', wins[1])
  chain(wins, 'down', 3)
  equalize(wins[1])
  -- Separator column between the main window and the stack
  local total = vim.api.nvim_win_get_width(wins[1]) + vim.api.nvim_win_get_width(wins[2]) + 1
  vim.api.nvim_win_set_width(wins[1], math.floor(total * opts.main_ratio))
end

-- Main window on top, the rest in a row below
-- @param wins number[] Window ids, main window first
-- @param opts ArrangeOpts
function arrange.fat(wins, opts)
  if #wins < 2 then
    return
  end
  window.new(wins[2]):place('down', wins[1])
  chain(wins, 'right', 3)
  equalize(wins[1])
  -- Status line between the main window and the row
  local total = vim.api.nvim_win_get_height(wins[1]) + vim.api.nvim_win_get_height(wins[2]) + 1
  vim.api.nvim_win_set_height(wins[1], math.floor(total * opts.main_ratio))
end

return arrange
