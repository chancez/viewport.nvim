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

-- Creates a mode to select a window from the current tabpage. When the mode is
-- started, a popup is opened above each window with a character to press to
-- select that window. Once the character is pressed, the corresponding window
-- is passed to the on_select function provided.
-- @param on_select function The function to call with the selected window
-- @param opts WindowSelectorOpts|nil Options for selection mode
-- @return Mode The created selection mode
-- @error Throws an error if there are more windows than available choices
function select_actions.new_window_selector_mode(on_select, opts)
  vim.validate("on_select", on_select, 'function')
  opts = vim.tbl_extend('force', WindowSelectorOpts, opts or {})

  -- TODO: Move all of this state into a new type or something.
  local popups = {}
  local selected_win = nil
  local keymaps = {}

  -- Creates popups above each window and updates keymaps to map each window
  -- selection key to the corresponding window.
  local create_popups = function()
    -- Reset values from previous calls
    keymaps = {
      -- Add the escape mapping because we overwrite keymaps entirely in the pre_start hook
      ['<Esc>'] = 'stop',
    }
    selected_win = nil
    popups = {}
    local windows = window.list_tab()
    if #windows > #opts.choices then
      error("Too many windows to select from. Max is " .. #opts.choices)
    end

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
      end

      ::continue::
    end
  end

  local close_popups = function()
    for _, popup in ipairs(popups) do
      -- Delete the temporary buffer, which also closes the window
      popup:delete_buffer()
    end
  end

  local should_restore_mode_mappings_display = false

  -- TODO: Find a way to disable other mappings and log a warning
  return mode.new({
    -- Mappings will be populated dynamically in pre_start
    pre_start = function(self)
      local current_mode = modes.get_active_mode()
      if current_mode and current_mode:is_mappings_display_shown() then
        should_restore_mode_mappings_display = true
        current_mode:close_mappings_display()
      end
      create_popups()
      -- assign the generated keymaps after popups are created
      self.config.mappings = {
        n = keymaps,
      }
    end,
    pre_stop = function()
      -- close popups in prestart to ensure they close even if an error occurs
      -- when the mode stopping
      close_popups()
    end,
    post_stop = function(self)
      -- reset mappings after stopping to avoid mappings persisting across different executions
      self.config.mappings = {}
      if selected_win then
        on_select(selected_win)
      end
      if should_restore_mode_mappings_display then
        local current_mode = modes.get_active_mode()
        if current_mode then
          current_mode:show_mappings_display()
        end
      end
    end,
    mapping_opts = { nowait = true },
  })
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


-- Opens a popup in the specified window with a list of choices. The user can
-- press the key corresponding to a choice to execute its action.
-- @param win number|Window The window to open the popup in
-- @param choices Choice[] List of choices to present to the user
-- @error Throws an error if the parameters are invalid
function select_actions.new_window_choice_picker(win, choices)
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
  local on_select = function(_) end

  local mappings = {}
  for _, choice in ipairs(choices) do
    -- Create a mapping which just sets action_callback
    -- and exits the mode
    mappings[choice.key] = function()
      on_select = choice.action
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
      on_select(win)
    end,
    mapping_opts = { nowait = true },
  }):start()
end

return action.from_module(select_actions)
