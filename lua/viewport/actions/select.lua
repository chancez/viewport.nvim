local window = require('viewport.window')
local mode = require('viewport.mode')
local action = require('viewport.action')
local modes = require('viewport.modes')

local select_actions = {}

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
-- @field selected_win Window|nil The selected window
-- @field mode Mode The underlying mode instance
local WindowSelectorMode = {}
WindowSelectorMode.__index = WindowSelectorMode
-- WindowSelectorMode inherits from Mode
setmetatable(WindowSelectorMode, { __index = mode.Mode })

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
  self.selected_win = nil
  self.should_restore_mappings_display = false
  return self
end

function WindowSelectorMode:_create_popups()
  local windows = window.list_tab()
  if #windows > #self.opts.choices then
    error("Too many windows to select from. Max is " .. #self.opts.choices)
  end

  local keymaps = { ['<Esc>'] = 'stop' }

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
      keymaps[choice] = function()
        self.selected_win = win
      end
    end
  end

  return keymaps
end

function WindowSelectorMode:pre_start()
  local current_mode = modes.get_active_mode()
  if current_mode and current_mode:is_mappings_display_shown() then
    self.should_restore_mappings_display = true
    current_mode:close_mappings_display()
  end

  local keymaps = self:_create_popups()
  self.config.mappings = { n = keymaps }
  mode.Mode.pre_start(self)
end

function WindowSelectorMode:pre_stop()
  self:_close_popups()
  mode.Mode.pre_stop(self)
end

function WindowSelectorMode:post_stop()
  if self.selected_win then
    self.on_select(self.selected_win)
  end

  if self.should_restore_mappings_display then
    local current_mode = modes.get_active_mode()
    if current_mode then
      current_mode:show_mappings_display()
    end
  end

  self.popups = {}
  self.selected_win = nil
  self.should_restore_mappings_display = false
  mode.Mode.post_stop(self)
end

function WindowSelectorMode:_close_popups()
  for _, popup in ipairs(self.popups) do
    popup:delete_buffer()
  end
  self.popups = {}
end

function WindowSelectorMode:_create_mode()
end

-- Creates a mode to select a window from the current tabpage. When the mode is
-- started, a popup is opened above each window with a character to press to
-- select that window. Once the character is pressed, the corresponding window
-- is passed to the on_select function provided.
-- @param on_select function The function to call with the selected window
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @return Mode The created selection mode
-- @error Throws an error if there are more windows than available choices
function select_actions.new_window_selector_mode(on_select, opts)
  return WindowSelectorMode.new(on_select, opts)
end

-- Starts a mode to select a window from the current tabpage and focuses it
-- when selected.
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function select_actions.select_window(opts)
  select_actions.new_window_selector_mode(
    function(win)
      win:focus()
    end,
    opts or {}
  ):start()
end

-- Creates a mode to select a window from the current tabpage. When the mode is
-- started, a popup is opened above each window with a character to press to
-- select that window. Once the character is pressed, the specified window
-- is swapped with the current window.
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function select_actions.new_swap_mode(opts)
  -- Create a mode that swaps the selected window with the specified window
  return select_actions.new_window_selector_mode(
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
    }, opts or {}))
end

-- @class Choice
-- @field key string Key to press to select this choice
-- @field text string Text to display for the choice
-- @field action function|string Action to perform when the choice is selected

-- @class WindowChoicePickerMode
-- @field win Window The window to open the popup in
-- @field choices Choice[] List of choices
-- @field popup Window|nil The popup window
-- @field selected_action function|string|nil The selected action
-- @field mode Mode The underlying mode instance
local WindowChoicePickerMode = {}
WindowChoicePickerMode.__index = WindowChoicePickerMode
setmetatable(WindowChoicePickerMode, { __index = mode.Mode })

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
  self.selected_action = nil
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

function WindowChoicePickerMode:_create_mappings()
  local mappings = {}
  for _, choice in ipairs(self.choices) do
    mappings[choice.key] = function()
      self.selected_action = choice.action
    end
  end
  return mappings
end

function WindowChoicePickerMode:pre_start()
  self:_create_popup()
  self.config.mappings = { n = self:_create_mappings() }
  mode.Mode.pre_start(self)
end

function WindowChoicePickerMode:post_stop()
  if self.popup then
    self.popup:delete_buffer()
    self.popup = nil
  end

  if self.selected_action then
    if type(self.selected_action) == 'function' then
      self.selected_action(self.win)
    end
    self.selected_action = nil
  end
  mode.Mode.post_stop(self)
end

-- Opens a popup in the specified window with a list of choices. The user can
-- press the key corresponding to a choice to execute its action.
-- @param win number|Window The window to open the popup in
-- @param choices Choice[] List of choices to present to the user
-- @error Throws an error if the parameters are invalid
function select_actions.new_window_choice_picker(win, choices)
  WindowChoicePickerMode.new(win, choices):start()
end

return action.from_module(select_actions)
