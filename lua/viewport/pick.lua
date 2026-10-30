local window = require('viewport.window')

-- Pickers show popups and read a single key with getcharstr(). They never
-- install mappings, so they can run from anywhere, including inside a mode,
-- and leave no state behind once they return.
local pick = {}

-- @class PickWindowOpts
-- @field choices string[] List of characters to use for selecting windows
-- @field horizontal_padding number Horizontal padding for the selection popup
-- @field should_exclude_window function Function that takes a window id and
-- returns true if it should be excluded from selection

-- Default options for picking a window
-- @type PickWindowOpts
local default_window_opts = {
  -- Use letters a-z to select windows
  choices = vim.split('abcdefghijklmnopqrstuvwxyz', ''),
  horizontal_padding = 4,
  should_exclude_window = function(_) return false end,
}

-- Redraws so popups are visible, then reads one key
-- @return string|nil The key pressed, or nil on <Esc> or interrupt
local function read_key()
  vim.cmd.redraw()
  local ok, key = pcall(vim.fn.getcharstr)
  if not ok or key == vim.keycode('<Esc>') or key == vim.keycode('<C-c>') then
    return nil
  end
  return key
end

-- Calls fn, then closes every popup in popups, even if fn errors
local function with_popups(popups, fn)
  local ok, result = pcall(fn)
  for _, popup in ipairs(popups) do
    popup:delete_buffer()
  end
  if not ok then
    error(result, 0)
  end
  return result
end

-- Opens a popup above each window in the current tabpage labelled with a
-- character, and waits for one to be pressed.
-- @param opts PickWindowOpts|nil Options for picking
-- @return Window|nil The window picked, or nil if cancelled
-- @error Throws an error if there are more windows than available choices
function pick.window(opts)
  opts = vim.tbl_extend('force', default_window_opts, opts or {})
  local windows = window.list_tab()
  if #windows > #opts.choices then
    error("Too many windows to select from. Max is " .. #opts.choices)
  end

  local popups = {}
  return with_popups(popups, function()
    local by_key = {}
    for i, win in ipairs(windows) do
      if not opts.should_exclude_window(win.id) then
        local choice = opts.choices[i]
        local text = "[" .. choice .. "]"
        local width = #text + opts.horizontal_padding
        text = string.rep(" ", math.floor((width - #text) / 2)) .. text

        table.insert(popups, window.open_popup({
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
        }))
        by_key[choice] = win
      end
    end

    if vim.tbl_isempty(by_key) then
      return nil
    end
    local key = read_key()
    return key and by_key[key]
  end)
end

-- @class Choice
-- @field key string Key to press to select this choice
-- @field text string Text to display for the choice
-- @field action function Called with the Window when the choice is selected

-- Opens a popup in win listing choices, and waits for one to be pressed.
-- @param win Window The window to open the popup in
-- @param choices Choice[] List of choices to present
-- @return Choice|nil The choice picked, or nil if cancelled
function pick.choice(win, choices)
  vim.validate("choices", choices, 'table')
  local lines = { "Choose action:" }
  for _, choice in ipairs(choices) do
    table.insert(lines, choice.text)
  end
  table.insert(lines, "[Esc] cancel")
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end

  local popups = {
    window.open_popup({
      win = win,
      buf_lines = lines,
      config = {
        width = width,
        height = #lines,
        title = "actions",
        title_pos = "center",
      },
    }),
  }
  return with_popups(popups, function()
    local key = read_key()
    if not key then
      return nil
    end
    for _, choice in ipairs(choices) do
      if vim.keycode(choice.key) == key then
        return choice
      end
    end
    return nil
  end)
end

-- Picks a window, then picks one of choices to run on it.
-- @param choices Choice[] List of choices to present once a window is picked
-- @param opts PickWindowOpts|nil Options for picking the window
function pick.window_action(choices, opts)
  local win = pick.window(opts)
  if not win then
    return
  end
  local choice = pick.choice(win, choices)
  if choice then
    choice.action(win)
  end
end

return pick
