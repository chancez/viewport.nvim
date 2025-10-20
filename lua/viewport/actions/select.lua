local window = require('viewport.window')
local mode = require('viewport.mode')
local action = require('viewport.action')
local modes = require('viewport.modes')

local select_actions = {}

-- @class WindowSelectorOpts
-- @field choices table List of characters to use for selecting windows
-- @field horizontal_padding number Horizontal padding for the selection popup
-- @field exclude_windows table List of window IDs to exclude from selection

-- Default options for select mode
-- @type WindowSelectorOpts
local WindowSelectorOpts = {
  -- Use letters a-z to select windows
  choices = vim.split('abcdefghijklmnopqrstuvwxyz', ''),
  horizontal_padding = 4,
  exclude_windows = {},
}

-- @class WindowSelectorMode
-- @field opts WindowSelectorOpts Options for the selector
-- @field on_select function Callback when window is selected
-- @field popups table List of popup windows
-- @field selected_win Window|nil The selected window
-- @field mode Mode The underlying mode instance
local WindowSelectorMode = {}
WindowSelectorMode.__index = WindowSelectorMode

function WindowSelectorMode.new(on_select, opts)
  vim.validate("on_select", on_select, 'function')
  local self = setmetatable({}, WindowSelectorMode)
  self.opts = vim.tbl_extend('force', WindowSelectorOpts, opts or {})
  self.on_select = on_select
  self:_reset()
  self.mode = self:_create_mode()
  return self
end

function WindowSelectorMode:_reset()
  self.popups = {}
  self.selected_win = nil
  self.should_restore_mappings_display = false
end

function WindowSelectorMode:_create_popups()
  local windows = window.list_tab()
  if #windows > #self.opts.choices then
    error("Too many windows to select from. Max is " .. #self.opts.choices)
  end

  local keymaps = { ['<Esc>'] = 'stop' }

  for i, win in ipairs(windows) do
    if not vim.tbl_contains(self.opts.exclude_windows, win.id) then
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

function WindowSelectorMode:_close_popups()
  for _, popup in ipairs(self.popups) do
    popup:delete_buffer()
  end
  self.popups = {}
end

function WindowSelectorMode:_create_mode()
  return mode.new({
    pre_start = function(m)
      local current_mode = modes.get_active_mode()
      if current_mode and current_mode:is_mappings_display_shown() then
        self.should_restore_mappings_display = true
        current_mode:close_mappings_display()
      end

      local keymaps = self:_create_popups()
      m.config.mappings = { n = keymaps }
    end,
    pre_stop = function()
      self:_close_popups()
    end,
    post_stop = function()
      if self.selected_win then
        self.on_select(self.selected_win)
      end

      if self.should_restore_mappings_display then
        local current_mode = modes.get_active_mode()
        if current_mode then
          current_mode:show_mappings_display()
        end
      end

      self:_reset()
    end,
    mapping_opts = { nowait = true },
  })
end

function WindowSelectorMode:start()
  self.mode:start()
end

function WindowSelectorMode:stop()
  self.mode:stop()
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
  return WindowSelectorMode.new(on_select, opts).mode
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
-- is swapped with the selected window.
-- @param win number|Window The window to swap with. If nil, uses the current window.
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @error Throws an error if there are more windows than available choices
function select_actions.new_swap_mode(win, opts)
  win = win or window.new()
  if type(win) == 'number' then
    win = window.new(win)
  end
  -- Create a mode that swaps the selected window with the specified window
  return select_actions.new_window_selector_mode(
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

-- @class WindowChoicePickerMode
-- @field win Window The window to open the popup in
-- @field choices Choice[] List of choices
-- @field popup Window|nil The popup window
-- @field selected_action function|nil The selected action
-- @field mode Mode The underlying mode instance
local WindowChoicePickerMode = {}
WindowChoicePickerMode.__index = WindowChoicePickerMode

function WindowChoicePickerMode.new(win, choices)
  vim.validate("win", win, { 'number', 'table' })
  vim.validate("choices", choices, 'table')
  for _, choice in ipairs(choices) do
    vim.validate("choice.key", choice.key, 'string')
    vim.validate("choice.text", choice.text, 'string')
    vim.validate("choice.action", choice.action, 'function')
  end

  local self = setmetatable({}, WindowChoicePickerMode)
  self.win = win
  self.choices = choices
  self.popup = nil
  self.selected_action = nil
  self.mode = self:_create_mode()
  return self
end

function WindowChoicePickerMode:_create_popup()
  local lines = { "Choose action:" }
  for _, choice in pairs(self.choices) do
    table.insert(lines, choice.text)
  end

  self.popup = window.open_popup({
    win = self.win,
    buf_lines = lines,
    config = {
      width = 20,
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

function WindowChoicePickerMode:_create_mode()
  return mode.new({
    pre_start = function(m)
      self:_create_popup()
      m.config.mappings = { n = self:_create_mappings() }
    end,
    post_stop = function()
      if self.popup then
        self.popup:delete_buffer()
        self.popup = nil
      end

      if self.selected_action then
        self.selected_action(self.win)
        self.selected_action = nil
      end
    end,
    mapping_opts = { nowait = true },
  })
end

function WindowChoicePickerMode:start()
  self.mode:start()
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
