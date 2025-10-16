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

-- @class WindowSelectorOpts
-- @field choices table List of characters to use for selecting windows
-- @field horizontal_padding number Horizontal padding for the selection popup
-- @field action function Function to call with the selected window
-- @field exclude_windows table List of window IDs to exclude from selection

-- Default options for select mode
-- @type WindowSelectorOpts
local WindowSelectorOpts = {
  -- Use letters a-z to select windows
  choices = vim.split('abcdefghijklmnopqrstuvwxyz', ''),
  horizontal_padding = 4,
  exclude_windows = {},
}

-- Starts a mode to select a window from the current tabpage. A popup is opened
-- above each window with a character to press to select that window. Once the
-- character is pressed, the corresponding window is passed to the action
-- function provided.
-- @param action function The function to call with the selected window
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function actions.new_window_selector(action, opts)
  vim.validate("action", action, 'function')
  opts = vim.tbl_extend('force', WindowSelectorOpts, opts or {})
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
        action(selected_win)
      end
    end,
    mapping_opts = { nowait = true },
  }):start()
end

-- Starts a mode to select a window from the current tabpage and focuses it
-- when selected.
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function actions.select_window(opts)
  actions.new_window_selector(
    function(win)
      win:focus()
    end,
    opts or {}
  )
  return true
end

-- Starts a mode to select a window from the current tabpage and swaps it
-- with the specified window when selected.
-- @param win number|Window The window to swap with. If nil, uses the current window.
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function actions.select_swap(win, opts)
  win = win or window.new()
  if type(win) == 'number' then
    win = window.new(win)
  end
  -- Open a selection to choose the window to swap with
  actions.new_window_selector(
    function(other_win)
      win:swap(other_win)
    end,
    vim.tbl_extend('keep', {
      -- When swapping, don't allow selecting the window already selected
      exclude_windows = { win.id },
    }, opts or {}))
end

-- @class Choice
-- @field key string Key to press to select this choice
-- @field text string Text to display for the choice
-- @field action function Function to call when the choice is selected


-- Opens a popup in the specified window with a list of choices. The user can
-- press the key corresponding to a choice to execute its action.
-- @param win number|Window The window to open the popup in
-- @param choices Choice[] List of choices to present to the user
-- @error Throws an error if the parameters are invalid
function actions.new_window_choice_picker(win, choices)
  vim.validate("win", win, { 'number', 'table' })
  vim.validate("choices", choices, 'table')
  for _, choice in ipairs(choices) do
    vim.validate("choice.key", choice.key, 'string')
    vim.validate("choice.text", choice.text, 'string')
    vim.validate("choice.action", choice.action, 'function')
  end

  local lines = { "Choose action:" }
  for _, choice in pairs(choices) do
    table.insert(lines, choice.text)
  end

  local popup = window.open_popup({
    win = win,
    buf_lines = lines,
    config = {
      width = 20,
      height = #lines,
      title = "actions",
      title_pos = "center",
    },
  })

  -- no-op if they don't pick anything
  local action_callback = function(_) end

  local mappings = {}
  for _, choice in ipairs(choices) do
    -- Create a mapping which just sets action_callback
    -- and exits the mode
    mappings[choice.key] = function()
      action_callback = choice.action
      -- Exit the mode after the choice is made
      return true
    end
  end

  mode.new({
    mappings = {
      n = mappings,
    },
    -- Close popups in case the user exits without making a choice
    post_stop = function()
      popup:delete_buffer()
      -- Execute the chosen action if any
      -- This must happen in the post_stop so that if the chosen
      -- action starts a sub-mode, the mappings this mode created
      -- have already been removed and existing mappings are restored
      -- before the new sub-mode starts.
      action_callback(win)
    end,
    mapping_opts = { nowait = true },
  }):start()
end

-- Starts a mode to select a window from the current tabpage and presents
-- a list of choices to perform on that window.
-- @param choices Choice[] List of choices to present to the user
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function actions.select_window_choices(choices, opts)
  opts = opts or {}
  actions.new_window_selector(
    function(win)
      actions.new_window_choice_picker(win, choices)
    end,
    opts
  )
end

return actions
