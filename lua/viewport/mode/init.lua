local keymap = require('viewport.mode.keymap')
local action = require('viewport.action')
local window = require('viewport.window')

local M = {}

-- @class Mode
-- @field active boolean Whether the mode is currently active
-- @field keymap_manager KeymapManager The keymap manager for buffer-local keymaps
-- @field config ModeConfig The mode configuration
local Mode = {}
Mode.__index = Mode

-- @class ModeConfig
-- @field mappings table Table of key mappings for the mode
-- @field action_opts table Options to pass to action functions
-- @field mapping_opts table Options to pass to vim.keymap.set
-- @field stop_after_action boolean Whether to stop the mode after an action is performed
-- @field display_mappings boolean Whether to display mappings in a popup when the mode starts
-- @field pre_start function Function called before mode starts
-- @field post_start function Function called after mode starts
-- @field pre_stop function Function called before mode stops
-- @field post_stop function Function called after mode stops

-- Default configuration for modes
-- @type ModeConfig
local default_mode_opts = {
  mappings = {
    i = {
      ['<Esc>'] = 'stop',
    },
    n = {
      ['<Esc>'] = 'stop',
      ['<Tab>'] = 'toggle_display_mappings',
    }
  },
  action_opts = {},
  mapping_opts = {},
  stop_after_action = true,
  display_mappings = false,
  pre_start = function(_) end,
  post_start = function(_) end,
  pre_stop = function(_) end,
  post_stop = function(_) end,
}

-- Creates a new Mode instance
-- @param config ModeConfig|nil Configuration for the mode
-- @return Mode A new Mode instance
function Mode.new(config)
  local self = setmetatable({}, Mode)
  self.active = false
  self.keymap_manager = keymap.new()
  self.config = vim.tbl_deep_extend('force', default_mode_opts, config or {})
  self.mappings_window = nil
  -- validate mappings
  vim.validate("mappings", self.config.mappings, 'table')
  for mode, mappings in pairs(self.config.mappings) do
    vim.validate("mode", mode, 'string')
    for lhs, rhs in pairs(mappings) do
      vim.validate("lhs", lhs, 'string')
      vim.validate("rhs", rhs, { 'function', 'callable', 'string', 'boolean' })
    end
  end
  return self
end

-- Starts the mode, activating key mappings and calling lifecycle hooks
function Mode:start()
  if self.active then
    return
  end
  self.active = true
  self.config.pre_start(self)

  local modes = vim.tbl_keys(self.config.mappings)
  self.keymap_manager:save(modes)

  for mode, mappings in pairs(self.config.mappings) do
    for lhs, rhs in pairs(mappings) do
      -- Allow a user to unset a default mapping by setting it to false
      if rhs ~= false then
        self:_add_mapping(mode, lhs, rhs)
      end
    end
  end

  if self.config.display_mappings then
    self:show_display_mappings()
  end

  self.config.post_start(self)
end

-- Adds a new mapping to the mode
-- @param mode string The vim mode for the keymap ('n', 'v', ' i', etc.)
-- @param lhs string The left-hand side (key sequence) of the mapping
-- @param rhs function|string The right-hand side (action) of the mapping
-- @param opts table|nil Options to pass to vim.keymap.set
function Mode:_add_mapping(mode, lhs, rhs, opts)
  vim.validate("mode", mode, 'string')
  vim.validate("lhs", lhs, 'string')
  vim.validate("rhs", rhs, { 'function', 'callable', 'string' })
  local desc = ''
  if getmetatable(rhs) == action.Action then
    desc = rhs:description()
  else
    if type(rhs) == 'function' then
      desc = "Viewport Action"
    elseif type(rhs) == 'string' and rhs == 'stop' then
      desc = "Stop Viewport Mode"
    elseif type(rhs) == 'string' and rhs == 'toggle_display_mappings' then
      desc = "Toggle Display Mappings"
    end
  end
  local mapping_opts = vim.tbl_extend('keep', { silent = true }, self.config.mapping_opts, opts or {}, { desc = desc })
  local wrapped_rhs = function()
    if rhs == 'stop' then
      self:stop()
    elseif rhs == 'toggle_display_mappings' then
      self:toggle_display_mappings()
    else
      rhs(self.config.action_opts)
      if self.config.stop_after_action then
        self:stop()
      end
    end
  end
  self.keymap_manager:set(mode, lhs, wrapped_rhs, mapping_opts)
end

-- Displays the current mappings in a popup window
function Mode:show_display_mappings()
  -- TODO: Handle mode changes. Currently most modes are normal only, and esc exits the modes
  local mappings = self.keymap_manager:get_keymaps().n
  local lines = {
    string.format(" %-10s | %s", "key", "desc")
  }
  -- Sort the mappings by lhs to ensure consistent order
  table.sort(mappings, function(a, b) return a.lhs < b.lhs end)

  for _, map in ipairs(mappings) do
    local text = string.format(" %-10s : %s", map.lhs, map.opts.desc or "")
    table.insert(lines, text)
  end
  local width = 30
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end
  -- Insert a line of dashes
  table.insert(lines, 2, string.rep("-", width))
  -- Open a popup displaying the mappings and their descriptions
  self.mappings_window = window.open_popup({
    buf_lines = lines,
    -- TODO: Make popup config customizable
    config = {
      width = width,
      height = #lines,
      title = "mode mappings", -- TODO: add mode name
      title_pos = "center",
      focusable = false,
    },
  })
  -- Move the window when the active window changes
  self.mapping_window_autocmd_id = vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      if self.mappings_window then
        local win = window.new()
        -- center of current window
        self.mappings_window:set_position(
          win:height() / 2, -- row
          win:width() / 2,  -- col
          'win',            -- relative
          win.id            -- win
        )
      end
    end,
  })
end

-- Closes the mappings display popup
function Mode:close_display_mappings()
  if self.mapping_window_autocmd_id then
    vim.api.nvim_del_autocmd(self.mapping_window_autocmd_id)
    self.mapping_window_autocmd_id = nil
  end
  if self.mappings_window then
    self.mappings_window:delete_buffer()
    self.mappings_window = nil
  end
end

-- Toggles the display of the mappings popup
function Mode:toggle_display_mappings()
  if self.mappings_window then
    self:close_display_mappings()
  else
    self:show_display_mappings()
  end
end

-- Stops the mode, restoring original key mappings and calling lifecycle hooks
function Mode:stop()
  self.config.pre_stop(self)
  self:close_display_mappings()
  self.keymap_manager:restore()
  self.config.post_stop(self)
  self.active = false
end

M.Mode = Mode

-- Creates a new Mode instance
-- @param config ModeConfig|nil Configuration for the mode
-- @return Mode A new Mode instance
M.new = function(config)
  return Mode.new(config)
end

return M
