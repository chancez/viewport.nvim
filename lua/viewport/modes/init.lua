local window = require('viewport.window')
local mode = require('viewport.mode')
local registry = require('viewport.mode.registry')
local mode_actions = require('viewport.mode.actions')

local modes = {}

-- @class WindowSelectorOpts
-- @field choices table List of characters to use for selecting windows
-- @field horizontal_padding number Horizontal padding for the selection popup
-- @field should_exclude_window function Function that takes a window id and
-- returns true if it should be excluded from selection

-- Default options for select mode
-- @type WindowSelectorOpts
local WindowSelectorOpts = {
  -- Use letters a-z to select windows
  choices = vim.split('abcdefghijklmnopqrstuvwxyz', ''),
  horizontal_padding = 4,
  should_exclude_window = function(_) return false end
}

-- @class WindowSelectorMode
-- @field opts WindowSelectorOpts Options for the selector
-- @field on_select function Callback when window is selected
-- @field popups table List of popup windows
-- @field mode Mode The underlying mode instance
local WindowSelectorMode = {}
WindowSelectorMode.__index = WindowSelectorMode
-- WindowSelectorMode inherits from Mode
setmetatable(WindowSelectorMode, mode.Mode)

-- Creates a mode to select a window from the current tabpage. When the mode is
-- started, a popup is opened above each window with a character to press to
-- select that window. Once the character is pressed, the corresponding window
-- is passed to the on_select function provided.
-- @param on_select function The function to call with the selected window
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @return WindowSelectorMode The created selection mode
function WindowSelectorMode.new(on_select, opts)
  vim.validate("on_select", on_select, 'function')
  vim.validate("opts", opts, { 'nil', 'table' })

  local self = mode.new({
    mapping_opts = { nowait = true },
  })

  setmetatable(self, WindowSelectorMode)

  self.opts = vim.tbl_extend('force', WindowSelectorOpts, opts or {})
  self.on_select = on_select
  self.popups = {}
  return self
end

function WindowSelectorMode:_create_popups()
  local windows = window.list_tab()
  if #windows > #self.opts.choices then
    error("Too many windows to select from. Max is " .. #self.opts.choices)
  end

  local keymaps = {
    -- Ensure stop mapping is present by default
    ['<Esc>'] = mode_actions.stop,
  }

  for i, win in ipairs(windows) do
    if not self.opts.should_exclude_window(win.id) then
      local choice = self.opts.choices[i]
      local text = "[" .. choice .. "]"
      local width = #text + self.opts.horizontal_padding
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

      table.insert(self.popups, popup)
      keymaps[choice] = function(_, _)
        self.on_select(win)
      end
    end
  end

  return keymaps
end

function WindowSelectorMode:pre_start()
  local keymaps = self:_create_popups()
  self.config.mappings = { n = keymaps }
  mode.Mode.pre_start(self)
end

function WindowSelectorMode:execute_action(action)
  self:_close_popups()
  -- Stop before executing action to avoid conflicts with nested modes and
  -- popups
  self:stop()
  -- TODO: I would like to 'wait' for the action to complete before stopping.
  -- Additionally, when the action is yet another mode, it's tricky because the
  -- action calls start(), and the new mode is 'active', but I'd like to wait
  -- for that mode to stop before considering the WindowSelectorMode to be
  -- "done".
  mode.Mode.execute_action(self, action)
end

function WindowSelectorMode:post_stop()
  self.popups = {}
  mode.Mode.post_stop(self)
end

function WindowSelectorMode:_close_popups()
  for _, popup in ipairs(self.popups) do
    popup:delete_buffer()
  end
  self.popups = {}
end

-- @class Choice
-- @field key string Key to press to select this choice
-- @field text string Text to display for the choice
-- @field action function|string Action to perform when the choice is selected

-- @class WindowChoicePickerMode
-- @field win Window The window to open the popup in
-- @field choices Choice[] List of choices
-- @field popup Window|nil The popup window
-- @field mode Mode The underlying mode instance
local WindowChoicePickerMode = {}
WindowChoicePickerMode.__index = WindowChoicePickerMode
setmetatable(WindowChoicePickerMode, mode.Mode)

-- Creates a mode that opens a popup in the specified window with a list of
-- choices. The user can press the key corresponding to a choice to execute its
-- action.
-- @param win number|Window The window to open the popup in
-- @param choices Choice[] List of choices to present to the user
function WindowChoicePickerMode.new(win, choices)
  vim.validate("win", win, { 'number', 'table' })
  vim.validate("choices", choices, 'table')
  for _, choice in ipairs(choices) do
    vim.validate("choice.key", choice.key, 'string')
    vim.validate("choice.text", choice.text, 'string')
    vim.validate("choice.action", choice.action, { 'function', 'string' })
  end

  local self = mode.new({
    mapping_opts = { nowait = true },
  })
  setmetatable(self, WindowChoicePickerMode)

  self.win = win
  self.choices = choices
  self.popup = nil
  return self
end

function WindowChoicePickerMode:_create_popup()
  local lines = { "Choose action:" }
  local width = #lines[1]
  for _, choice in pairs(self.choices) do
    if #choice.text > width then
      width = #choice.text
    end
    table.insert(lines, choice.text)
  end

  self.popup = window.open_popup({
    win = self.win,
    buf_lines = lines,
    config = {
      width = width,
      height = #lines,
      title = "actions",
      title_pos = "center",
    },
  })
end

function WindowChoicePickerMode:_close_popup()
  if self.popup then
    self.popup:delete_buffer()
    self.popup = nil
  end
end

function WindowChoicePickerMode:_create_mappings()
  local mappings = {}
  for _, choice in ipairs(self.choices) do
    mappings[choice.key] = function(_, _)
      choice.action(self, self.win)
    end
  end
  return mappings
end

function WindowChoicePickerMode:pre_start()
  self:_create_popup()
  self.config.mappings = { n = self:_create_mappings() }
  mode.Mode.pre_start(self)
end

function WindowChoicePickerMode:execute_action(action)
  self:_close_popup()
  -- Stop before executing action to avoid conflicts with nested modes and
  -- popups
  self:stop()
  mode.Mode.execute_action(self, action)
end

function WindowChoicePickerMode:post_stop()
  self:_close_popup()
  mode.Mode.post_stop(self)
end

-- @class SwapWindowMode
local SwapWindowMode = {}
SwapWindowMode.__index = SwapWindowMode
-- SwapWindowMode inherits from WindowSelectorMode
setmetatable(SwapWindowMode, WindowSelectorMode)

-- Creates a mode to select a window from the current tabpage. When the mode is
-- started, a popup is opened above each window with a character to press to
-- select that window. Once the character is pressed, the specified window
-- is swapped with the current window.
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function SwapWindowMode.new(opts)
  -- Create a mode that swaps the selected window with the specified window
  local self = WindowSelectorMode.new(
    function(other_win)
      local current_win = window.new()
      current_win:swap(other_win)
    end,
    vim.tbl_extend('keep', {
      -- When swapping, don't allow selecting the window already selected
      should_exclude_window = function(win_id)
        local current_win = window.new()
        return win_id == current_win.id
      end,
    }, opts or {})
  )
  setmetatable(self, SwapWindowMode)
  return self
end

-- @class SelectMode
local SelectMode = {}
SelectMode.__index = SelectMode
setmetatable(SelectMode, WindowSelectorMode)

-- Creates a mode to select a window from the current tabpage. When the mode is
-- started, a popup is opened above each window with a character to press to
-- select that window. Once the character is pressed, the corresponding window
-- has a ChoicePickerMode opened to select an action to perform on that window.
function SelectMode.new(opts)
  local self = WindowSelectorMode.new(
    function(win)
      WindowChoicePickerMode.new(win, opts.select_mode.choices):start()
    end
  )

  setmetatable(self, SelectMode)
  return self
end

modes.WindowSelectorMode = WindowSelectorMode
modes.WindowChoicePickerMode = WindowChoicePickerMode
modes.SwapWindowMode = SwapWindowMode
modes.SelectMode = SelectMode

return modes
