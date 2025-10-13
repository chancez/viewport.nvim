local M = {}

-- Gets the current buffer mapping for a specific mode
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
-- @param buffer number Buffer handle (0 for current buffer)
-- @return table Array of maparg()-like dictionaries describing mappings.
local function get_buffer_mappings(mode, buffer)
  return vim.api.nvim_buf_get_keymap(buffer, mode)
end

-- Gets the current global mappings for a specific mode
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
-- @return table Array of |maparg()|-like dictionaries describing mappings. The
-- "buffer" key is always zero.
local function get_global_mappings(mode)
  return vim.api.nvim_get_keymap(mode)
end

-- Sets a buffer-local keymap on a specific buffer
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
-- @param lhs string The left-hand side (key sequence) of the mapping
-- @param rhs function|string The right-hand side (action) of the mapping
-- @param opts table|nil Options to pass to vim.keymap.set
-- @param buffer number Buffer handle
local function set_buffer_keymap(mode, lhs, rhs, opts, buffer)
  local buffer_opts = vim.tbl_extend('force', opts or {}, { buffer = buffer })
  vim.keymap.set(mode, lhs, rhs, buffer_opts)
end

-- Keymap manager class
local KeymapManager = {}
KeymapManager.__index = KeymapManager

-- Creates a keymap manager that can set buffer-local keymaps and restore them
-- @return KeymapManager A keymap manager instance
function M.new()
  local self = setmetatable({
    global_mappings = {},
    buffer_mappings = {},
    keymaps         = {},
    autocmd_group   = nil,
  }, KeymapManager)

  return self
end

-- Saves the current global and buffer-local mappings for a specific mode
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
function KeymapManager:save(mode)
  -- Store the global mappings
  self.global_mappings[mode] = get_global_mappings(mode)

  -- Store buffer mappings for all current buffers
  local buffer_mappings = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      buffer_mappings[buf] = get_buffer_mappings(mode, buf)
    end
  end
  self.buffer_mappings[mode] = buffer_mappings

  -- Create autocmd group if it doesn't exist
  if not self.autocmd_group then
    self.autocmd_group = vim.api.nvim_create_augroup(
      string.format('ViewportModeKeymaps_%s_%s', mode, tostring(self)),
      { clear = true }
    )
  end
end

-- Sets keymaps on all existing buffers and sets up autocmd for new buffers
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
-- @param lhs string The left-hand side (key sequence) of the mapping
-- @param rhs function|string The right-hand side (action) of the mapping
-- @param opts table|nil Options to pass to vim.keymap.set
function KeymapManager:set(mode, lhs, rhs, opts)
  -- We use a buffer local keymap because it takes precedence over global
  -- keymaps

  -- Set buffer-local keymaps on all current buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      set_buffer_keymap(mode, lhs, rhs, opts, buf)
    end
  end

  -- Create autocmd to set keymap on new buffers
  local autocmd_id = vim.api.nvim_create_autocmd('BufEnter', {
    group = self.autocmd_group,
    callback = function(ev)
      set_buffer_keymap(mode, lhs, rhs, opts, ev.buf)
    end,
  })

  -- Store the keymap state for this mapping
  local keymap_state = {
    lhs = lhs,
    autocmd_id = autocmd_id,
  }

  if not self.keymaps[mode] then
    self.keymaps[mode] = {}
  end

  -- Add to manager's keymaps
  table.insert(self.keymaps[mode], keymap_state)
end

-- Deletes all keymaps set by this manager for a specific mode
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
function KeymapManager:__delete(mode)
  if not self.keymaps[mode] then
    return
  end
  for _, keymap in pairs(self.keymaps[mode]) do
    -- Remove autocmd
    if keymap.autocmd_id then
      vim.api.nvim_del_autocmd(keymap.autocmd_id)
    end

    -- Delete buffer-local mappings from all current buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        -- pcall because a mapping may not be set.
        -- Mappings are set on buffers that were loaded when we call save(),
        -- and later on BufEnter. So if a new buffer is created, but we never
        -- entered it, the mappings won't be set.
        pcall(vim.api.nvim_buf_del_keymap, buf, mode, keymap.lhs)
      end
    end
  end
  self.keymaps[mode] = nil
end

-- Restores the saved global and buffer-local mappings for a specific mode
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
function KeymapManager:restore(mode)
  -- Delete all keymaps set by this manager before restoring
  self:__delete(mode)

  -- Clear the autocmd group
  if self.autocmd_group then
    vim.api.nvim_del_augroup_by_id(self.autocmd_group)
    self.autocmd_group = nil
  end


  -- Restore global mappings
  if self.global_mappings[mode] then
    for _, mappings in ipairs(self.global_mappings[mode]) do
      for _, mapping in ipairs(mappings) do
        vim.fn.mapset(mapping)
      end
    end
  end

  -- Restore buffer mappings
  if self.buffer_mappings[mode] then
    for buf, mappings in pairs(self.buffer_mappings[mode]) do
      if vim.api.nvim_buf_is_valid(buf) then
        for _, mapping in ipairs(mappings) do
          vim.fn.mapset(mapping)
        end
      end
    end
  end
end

return M
