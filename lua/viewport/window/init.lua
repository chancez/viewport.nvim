local utils = require('viewport.window.utils')

local M = {}

-- @class Window
-- @field id number The window id
local Window = {}
Window.__index = Window

-- Creates a new Window instance
-- @param id number|nil The window id (defaults to current window)
-- @return Window A new Window instance
function Window.new(id)
  local self = setmetatable({}, Window)
  self.id = id or vim.api.nvim_get_current_win()
  return self
end

-- Returns a string representation of the window
-- @return string String representation showing window id
function Window:__tostring()
  return string.format("Window(id=%d)", self.id)
end

-- Returns detailed information about the window
-- @return string Detailed string with position and size information
function Window:details()
  return string.format("Window(id=%d, top=%d, bottom=%d, left=%d, right=%d, height=%d, width=%d)",
    self.id, self:top(), self:bottom(), self:left(), self:right(), self:height(), self:width())
end

-- Gets the top position of the window
-- @return number The row position of the top edge
function Window:top()
  return vim.api.nvim_win_get_position(self.id)[1]
end

-- Gets the bottom position of the window
-- @return number The row position of the bottom edge
function Window:bottom()
  return self:top() + self:height()
end

-- Gets the left position of the window
-- @return number The column position of the left edge
function Window:left()
  return vim.api.nvim_win_get_position(self.id)[2]
end

-- Gets the right position of the window
-- @return number The column position of the right edge
function Window:right()
  return self:left() + self:width()
end

-- Gets the height of the window
-- @return number The height in rows
function Window:height()
  return vim.api.nvim_win_get_height(self.id)
end

-- Gets the width of the window
-- @return number The width in columns
function Window:width()
  return vim.api.nvim_win_get_width(self.id)
end

-- Checks if this window's top edge touches another window's bottom edge
-- @param other Window The other window to check against
-- @return boolean True if the windows touch
function Window:top_touches(other)
  return (other:bottom() + 1) == self:top()
end

-- Checks if this window's bottom edge touches another window's top edge
-- @param other Window The other window to check against
-- @return boolean True if the windows touch
function Window:bottom_touches(other)
  return other:top() == (self:bottom() + 1)
end

-- Checks if this window's left edge touches another window's right edge
-- @param other Window The other window to check against
-- @return boolean True if the windows touch
function Window:left_touches(other)
  return (self:left() - 1) == other:right()
end

-- Checks if this window's right edge touches another window's left edge
-- @param other Window The other window to check against
-- @return boolean True if the windows touch
function Window:right_touches(other)
  return self:right() == (other:left() - 1)
end

-- Checks if this window's horizontal sides are within another window's bounds
-- @param other Window The other window to check against
-- @return boolean True if any horizontal side is within the other window
function Window:horizontal_sides_within(other)
  return utils.within(self:left(), other:left(), other:right()) or
      utils.within(self:right(), other:left(), other:right())
end

-- Checks if this window's vertical sides are within another window's bounds
-- @param other Window The other window to check against
-- @return boolean True if any vertical side is within the other window
function Window:vertical_sides_within(other)
  return utils.within(self:top(), other:top(), other:bottom()) or
      utils.within(self:bottom(), other:top(), other:bottom())
end

-- Checks if this window is directly above another window
-- @param other Window The other window to check against
-- @return boolean True if this window is above the other
function Window:is_above(other)
  return self:bottom_touches(other) and (self:horizontal_sides_within(other) or other:horizontal_sides_within(self))
end

-- Checks if this window is directly below another window
-- @param other Window The other window to check against
-- @return boolean True if this window is below the other
function Window:is_below(other)
  return self:top_touches(other) and (self:horizontal_sides_within(other) or other:horizontal_sides_within(self))
end

-- Checks if this window is directly left of another window
-- @param other Window The other window to check against
-- @return boolean True if this window is left of the other
function Window:is_left_of(other)
  return self:right_touches(other) and (self:vertical_sides_within(other) or other:vertical_sides_within(self))
end

-- Checks if this window is directly right of another window
-- @param other Window The other window to check against
-- @return boolean True if this window is right of the other
function Window:is_right_of(other)
  return self:left_touches(other) and (self:vertical_sides_within(other) or other:vertical_sides_within(self))
end

-- Gets all neighboring windows in each direction
-- @return table Table with keys 'left', 'right', 'up', 'down' containing arrays of Window objects
function Window:neighbors()
  local neighbors = {
    left = {},
    right = {},
    up = {},
    down = {},
  }

  local wins = M.list_tab()

  -- Collect all non-floating windows except the current one
  for _, other in ipairs(wins) do
    -- Filter out floating windows
    if other.id ~= self.id and not utils.is_relative(other.id) then
      -- Check if the other window is directly above
      if other:is_above(self) then
        table.insert(neighbors.up, other)
      end

      -- check if the other window is directly below
      if other:is_below(self) then
        table.insert(neighbors.down, other)
      end

      -- Check if the other window is directly to the left
      if other:is_left_of(self) then
        table.insert(neighbors.left, other)
      end

      -- Check if the other window is directly to the right
      if other:is_right_of(self) then
        table.insert(neighbors.right, other)
      end
    end
  end

  return neighbors
end

-- Mapping of direction names to vim direction letters
local direction_to_letter = {
  left   = "h",
  right  = "l",
  above  = "k",
  up     = "k",
  top    = "k",
  below  = "j",
  down   = "j",
  bottom = "j",
}

-- Gets the neighboring window in a specific direction
-- @param direction string The direction to look ("left", "right", "up", "down", etc.)
-- @return Window|false The neighboring window or false if none exists
function Window:neighbor(direction)
  local letter = direction_to_letter[direction]
  if not letter then
    error(string.format("Invalid direction '%s'. Valid directions are: %s", direction,
      table.concat(vim.tbl_keys(direction_to_letter), ", ")))
  end
  local neighbor_nr = vim.fn.winnr(letter)
  -- check if it's a popup
  if neighbor_nr == 0 then
    return false
  end
  -- Check if it's ourself
  local id = vim.fn.win_getid(neighbor_nr)
  if id == self.id then
    return false
  end
  local neighbor = Window.new(id)
  return neighbor
end

-- Resizes the window from the top edge
-- @param amount number The amount to resize by (positive to grow down)
function Window:resize_top(amount)
  vim.validate('amount', amount, 'number')
  amount = amount or 1
  -- Decrease the size of the window above us
  local neighbor = self:neighbor("above")
  if neighbor then
    neighbor:resize_bottom(-amount)
  end
end

-- Resizes the window from the bottom edge
-- @param amount number The amount to resize by (positive to grow down)
function Window:resize_bottom(amount)
  vim.validate('amount', amount, 'number')
  amount = amount or 1
  -- Only resize in a direction if it's possible
  -- If we don't have a neighbor below us, we can't "grow down".
  -- Doing so would result in "growing up".
  -- We also should not attempt to "shrink up" without the bottom neighbor.
  -- This results in the buffer shrinking, but without anything to take up the space.
  local neighbor = self:neighbor("below")
  if not neighbor then
    return
  end
  vim.api.nvim_win_set_height(self.id, self:height() + amount)
end

-- Resizes the window from the right edge
-- @param amount number The amount to resize by (positive to grow right)
function Window:resize_right(amount)
  vim.validate('amount', amount, 'number')
  amount = amount or 1
  -- Only resize in a direction if it's possible
  -- If we don't have a neighbor to our right, we can't grow "right".
  -- Doing so would result in growing to the "left".
  if amount > 0 then
    local neighbor = self:neighbor("right")
    if not neighbor then
      return
    end
  end
  vim.api.nvim_win_set_width(self.id, self:width() + amount)
end

-- Resizes the window from the left edge
-- @param amount number The amount to resize by (positive to grow left)
function Window:resize_left(amount)
  vim.validate('amount', amount, 'number')
  amount = amount or 1
  -- Decrease the size of the window to our left
  local neighbor = self:neighbor("left")
  if neighbor then
    neighbor:resize_right(-amount)
  end
end

-- Mapping of resize directions to side methods
local resize_direction_to_side = {
  up    = "top",
  down  = "bottom",
  left  = "left",
  right = "right",
}

-- Mapping of directions to their opposites
local opposite_directions = {
  up    = "down",
  down  = "up",
  left  = "right",
  right = "left",
}

-- Resizes the window in a specific direction
-- @param direction string The direction to resize ("up", "down", "left", "right")
-- @param amount number The amount to resize by
function Window:resize(direction, amount)
  vim.validate {
    direction = { direction, 'string' },
    amount = { amount, 'number' }
  }
  amount = amount or 1
  local dir = resize_direction_to_side[direction]
  if not dir then
    error(string.format("Invalid direction '%s'. Valid directions are: up, down, left, right", direction))
  end
  local f = self["resize_" .. dir]
  f(self, amount)
end

-- Resizes the window relative to its neighbors
-- @param direction string The direction to resize ("up", "down", "left", "right")
-- @param amount number The amount to resize by
function Window:relative_resize(direction, amount)
  -- relative resizing takes neighbors into consideration
  vim.validate {
    direction = { direction, 'string' },
    amount = { amount, 'number' }
  }
  amount = amount or 1

  local opposite_direction = opposite_directions[direction]
  -- Up and left are special, we need to check if we have a neighbor on
  -- both sides, if we do, we shrink,
  -- Otherwise we grow if we have a neighbor in the direction specified.
  if (direction == 'up' or direction == 'left') and self:neighbor(direction) and self:neighbor(opposite_direction) then
    -- Shrink the opposite side
    amount = -amount
    direction = opposite_direction
  else
    -- Update amount before we change the direction below, as this relies on
    -- knowing the original direction.
    amount = self:neighbor(direction) and amount or -amount
    -- If we do not have a neighbor in the direction we're changing, then
    -- inverting the direction is logically simpler.
    -- Instead of shrinking the side we don't have a neighbor which actually
    -- results in "growing", we should grow the opposite side, which is more intuitive.
    direction = self:neighbor(direction) and direction or opposite_direction
  end

  local side = resize_direction_to_side[direction]
  self["resize_" .. side](self, amount)
end

-- Focuses this window
function Window:focus()
  vim.api.nvim_set_current_win(self.id)
end

-- Focuses a neighboring window in the specified direction
-- @param direction string The direction to focus ("up", "down", "left", "right")
function Window:focus_direction(direction)
  vim.validate { direction = { direction, 'string' } }
  local letter = direction_to_letter[direction]
  if not letter then
    error(string.format("Invalid direction '%s'. Valid directions are: %s", direction,
      table.concat(vim.tbl_keys(direction_to_letter), ", ")))
  end
  local cmd = string.format("wincmd %s", letter)
  vim.cmd(cmd)
end

-- Checks if this window is currently focused
-- @return boolean True if this window is focused
function Window:is_focused()
  return self.id == vim.api.nvim_get_current_win()
end

-- Gets the buffer displayed in this window
-- @return number The buffer number
function Window:get_buffer()
  if not self.id then
    return nil
  end
  return vim.api.nvim_win_get_buf(self.id)
end

-- Sets the buffer displayed in this window
-- @param bufnr number The buffer number to display
function Window:set_buffer(bufnr)
  vim.validate('bufnr', bufnr, 'number')
  vim.api.nvim_win_set_buf(self.id, bufnr)
end

-- Deletes the buffer displayed in this window and invalidates the window
-- @return boolean True if the buffer was deleted successfully
function Window:delete_buffer()
  local buf = self:get_buffer()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
    -- Unset the window id since the window is now invalid
    self.id = nil
    return true
  end
  return false
end

-- Moves this window in the specified direction
-- @param direction string The direction to move the window
function Window:move(direction)
  vim.validate { direction = { direction, 'string' } }
  local letter = direction_to_letter[direction]
  if not letter then
    error(string.format("Invalid direction '%s'. Valid directions are: %s", direction,
      table.concat(vim.tbl_keys(direction_to_letter), ", ")))
  end
  local cmd = string.format("wincmd %s", letter:upper())
  vim.cmd(cmd)
end

-- Swaps the buffer in this window with a neighboring window in the specified direction
-- @param direction string The direction of the window to swap with
-- @return boolean True if the swap was successful, false if no neighbor exists
function Window:swap_direction(direction)
  vim.validate { direction = { direction, 'string' } }
  local letter = direction_to_letter[direction]
  if not letter then
    error(string.format("Invalid direction '%s'. Valid directions are: %s", direction,
      table.concat(vim.tbl_keys(direction_to_letter), ", ")))
  end
  local neighbor = self:neighbor(direction)
  if not neighbor then
    return false
  end
  return self:swap(neighbor)
end

-- Swaps the buffer in this window with another window
-- @param other Window|number The other window or its id.
-- @return boolean True if the swap was successful
function Window:swap(other)
  -- If other is a window ID, convert it to a Window object
  if type(other) == "number" then
    other = Window.new(other)
  end
  local current_buf = self:get_buffer()
  local other_buf = other:get_buffer()
  self:set_buffer(other_buf)
  other:set_buffer(current_buf)
  return true
end

-- Checks if this window is still open and valid
-- @return boolean True if the window is open
function Window:is_open()
  return self.id ~= nil and vim.api.nvim_win_is_valid(self.id)
end

-- Closes the window if it's open
function Window:close()
  if not self:is_open() then
    return
  end
  vim.api.nvim_win_close(self.id, true)
  self.id = nil
end

M.Window = Window

-- Lists all windows in the current tab
-- @param tabnr number|nil The tab number (defaults to current tab)
-- @return Window[] Array of Window objects
function M.list_tab(tabnr)
  local wins = vim.api.nvim_tabpage_list_wins(tabnr or 0)
  local result = {}
  for _, id in ipairs(wins) do
    -- Filter out floating windows
    if not utils.is_relative(id) then
      table.insert(result, Window.new(id))
    end
  end
  return result
end

-- Creates a new Window instance
-- @param id number|nil The window id (defaults to current window)
-- @return Window A new Window instance
M.new = Window.new

-- @class WindowOpenOpts
-- @field bufnr number|nil The buffer to display in the window
-- @field enter boolean|nil Whether to enter the window after creation
-- @field config vim.api.keyset.win_config|nil Window configuration options

-- Opens a new window with the given options and returns a Window object
-- @param opts WindowOpenOpts|nil Options for creating the window
-- @return Window The created Window object
function M.open(opts)
  opts = opts or {}
  local id = vim.api.nvim_open_win(opts.bufnr or 0, opts.enter or false, opts.config or {})
  return Window.new(id)
end

-- @class WindowPopupOpts
-- @field win Window|nil The window to position the popup relative to (defaults to current window)
-- @field buf number|nil The buffer to display in the popup (created if not provided)
-- @field buf_name string|nil The name to set for the buffer created
-- @field buf_lines string[]|nil Lines to set in the buffer created
-- @field enter boolean|nil Whether to enter the popup window after creation (defaults to false)
-- @field config vim.api.keyset.win_config|nil Configuration for the popup window (position, size, border, etc.)

-- Opens a popup window with the given options and returns a Window object
-- @param opts WindowPopupOpts Options for creating the popup
-- @return Window The created popup Window object
function M.open_popup(opts)
  local win = opts.win or Window.new()
  local buf = opts.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
  end
  if opts.buf_name then
    vim.api.nvim_buf_set_name(buf, opts.buf_name)
  end
  if opts.buf_lines then
    -- TODO: This is maybe a bit limited. Maybe should just make it easier to
    -- create the buffer and only provide it instead.
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, opts.buf_lines)
  end
  local popup_config = vim.tbl_extend('force', {
      relative = 'win',
      win = win.id,
      style = 'minimal',
      -- position in the middle of the window by default
      row = win:height() / 2,
      col = win:width() / 2,
      noautocmd = true,
      border = 'rounded',
    },
    opts.config)

  local popup = M.open({
    bufnr = buf,
    enter = opts.enter or false,
    config = popup_config,
  })
  return popup
end

return M
