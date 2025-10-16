local window = require('viewport.window')
local mode = require('viewport.mode')

local actions = {}

-- Focuses a window in the specified direction
-- @param direction string The direction to focus ("up", "down", "left", "right")
-- @return boolean True if a window was found and focused, false otherwise
local function focus_window(direction)
  local current_window = window.new()
  local neighbor = current_window:neighbor(direction)
  if neighbor then
    neighbor:focus()
    return true
  end
  return false
end

-- Moves the current window in the specified direction
-- @param direction string The direction to move the window
local function move_window(direction)
  local current_window = window.new()
  -- TODO: Do we need to check if the move is valid?
  current_window:move(direction)
end

-- Swaps the current window with a window in the specified direction
-- @param direction string The direction to swap with
-- @return boolean True if the swap was successful, false otherwise
local function swap_window_direction(direction)
  local current_window = window.new()
  return current_window:swap_direction(direction)
end

-- Focuses the window above the current one
function actions.focus_above()
  focus_window("up")
end

-- Focuses the window below the current one
function actions.focus_below()
  focus_window("down")
end

-- Focuses the window to the left of the current one
function actions.focus_left()
  focus_window("left")
end

-- Focuses the window to the right of the current one
function actions.focus_right()
  focus_window("right")
end

-- Moves the current window up
function actions.move_up()
  move_window("up")
end

-- Moves the current window down
function actions.move_down()
  move_window("down")
end

-- Moves the current window left
function actions.move_left()
  move_window("left")
end

-- Moves the current window right
function actions.move_right()
  move_window("right")
end

-- Swaps the current window with the one above and focuses it
function actions.swap_above()
  if swap_window_direction("up") then
    focus_window("up")
  end
end

-- Swaps the current window with the one below and focuses it
function actions.swap_below()
  if swap_window_direction("down") then
    focus_window("down")
  end
end

-- Swaps the current window with the one to the left and focuses it
function actions.swap_left()
  if swap_window_direction("left") then
    focus_window("left")
  end
end

-- Swaps the current window with the one to the right and focuses it
function actions.swap_right()
  if swap_window_direction("right") then
    focus_window("right")
  end
end

-- @class SelectModeOpts
-- @field choices table List of characters to use for selecting windows
-- @field horizontal_padding number Horizontal padding for the selection popup
-- @field action function Function to call with the selected window
-- @field exclude_windows table List of window IDs to exclude from selection

-- Default options for select mode
-- @type SelectModeOpts
local select_choices_default_opts = {
  -- Use letters a-z to select windows
  choices = vim.split('abcdefghijklmnopqrstuvwxyz', ''),
  action = function(win)
    win:focus()
  end,
  horizontal_padding = 4,
  exclude_windows = {},
}

-- Enters window selection mode, showing a popup over each window with a selectable character
-- @param opts SelectModeOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function actions.select_mode(opts)
  opts = vim.tbl_extend('force', select_choices_default_opts, opts or {})
  local windows = window.list_tab()
  local keymaps = {}
  local popups = {}
  if #windows > #opts.choices then
    error("Too many windows to select from. Max is " .. #opts.choices)
  end

  local close_popups = function()
    for _, popup in ipairs(popups) do
      -- Delete the temporary buffer, which also closes the window
      popup:delete_buffer()
    end
  end

  local selected_win = nil
  for i, win in ipairs(windows) do
    -- Check if this window should be excluded
    if vim.tbl_contains(opts.exclude_windows, win.id) then
      goto continue
    end

    -- Create a popup above each window with one of the choices
    local choice = opts.choices[i]
    local text = "[" .. choice .. "]"
    local width = #text + opts.horizontal_padding
    -- Insert the text in the middle of the buffer
    text = string.rep(" ", math.floor((width - #text) / 2)) .. text
    local popup = window.open_popup({
      win = win,
      buf_lines = { text },
      config = {
        width = width,
        height = 1,
        title = "select",
        footer = "window",
        title_pos = "center",
        footer_pos = "center",
      },
    })

    -- Track popups so we can close them later
    table.insert(popups, popup)
    -- Configure the mapping for this choice
    keymaps[choice] = function()
      selected_win = win
      return true
    end

    ::continue::
  end

  -- TODO: Find a way to disable other mappings and log a warning
  mode.new({
    mappings = {
      n = keymaps,
    },
    post_stop = function()
      close_popups()
      if selected_win then
        opts.action(selected_win)
      end
    end,
    mapping_opts = { nowait = true },
  }):start()
end

return actions
