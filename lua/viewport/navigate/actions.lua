local window = require('viewport.window')
local mode = require('viewport.mode')

local actions = {}

-- @class SelectModeOpts
-- @field choices table List of characters to use for selecting windows
-- @field horizontal_padding number Horizontal padding for the selection popup

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

-- Default options for select mode
-- @type SelectModeOpts
local select_choices_default_opts = {
  -- Use letters a-z to select windows
  choices = vim.split('abcdefghijklmnopqrstuvwxyz', ''),
  action = function(win)
    win:focus()
    -- Tell the mode to stop after this action
    return true
  end,
  horizontal_padding = 4,
}

-- Enters window selection mode, showing a popup over each window with a selectable character
-- @param opts SelectModeOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function actions.select_mode(opts)
  opts = vim.tbl_extend('keep', opts or {}, select_choices_default_opts)
  local windows = window.list_tab()
  local keymaps = {}
  local popups = {}
  if #windows > #opts.choices then
    error("Too many windows to select from. Max is " .. #opts.choices)
  end
  for i, win in ipairs(windows) do
    -- Create a popup above each window with one of the choices
    local buf = vim.api.nvim_create_buf(false, true)
    local choice = opts.choices[i]
    local text = "[" .. choice .. "]"
    local width = #text + opts.horizontal_padding
    -- Insert the text in the middle of the buffer
    text = string.rep(" ", math.floor((width - #text) / 2)) .. text
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
    local popup = window.open({
      bufnr = buf,
      config = {
        relative = 'win',
        win = win.id,
        style = 'minimal',
        -- position in the middle of the window
        row = win:height() / 2,
        col = win:width() / 2,
        width = width,
        height = 1,
        title = "select",
        footer = "window",
        title_pos = "center",
        footer_pos = "center",
        noautocmd = true,
        border = 'rounded',
      }
    })
    -- Track popups so we can close them later
    table.insert(popups, popup)
    -- Configure the mapping for this choice
    keymaps[choice] = function()
      return opts.action(win)
    end
  end

  -- TODO: Find a way to disable other mappings and log a warning
  mode.new({
    mappings = {
      n = keymaps,
    },
    mapping_opts = { nowait = true },
    post_stop = function()
      -- Close all popups
      for _, popup in ipairs(popups) do
        -- Delete the temporary buffer, which also closes the window
        popup:delete_buffer()
      end
    end
  }):start()
end

return actions
