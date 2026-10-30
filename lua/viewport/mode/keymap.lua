local M = {}

-- Gets the buffer-local mapping for lhs in a buffer, if any
-- @param buf number Buffer handle
-- @param mode string The vim mode for the keymap ('n', 'v', 'i', etc.)
-- @param lhs string The left-hand side (key sequence) of the mapping
-- @return table|nil A maparg()-like dictionary describing the mapping
local function get_buffer_mapping(buf, mode, lhs)
  local raw = vim.keycode(lhs)
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    if vim.keycode(mapping.lhs) == raw then
      return mapping
    end
  end
  return nil
end

-- Keymap manager class
local KeymapManager = {}
KeymapManager.__index = KeymapManager

-- Creates a keymap manager that can set buffer-local keymaps and restore them
-- @return KeymapManager A keymap manager instance
function M.new()
  local self = setmetatable({
    keymaps       = {},
    -- Mappings that were replaced, keyed by buffer, then mode, then lhs.
    -- false means there was no mapping to restore.
    replaced      = {},
    autocmd_group = nil,
  }, KeymapManager)

  return self
end

-- Prepares the manager to set mappings. Mappings that get replaced are saved
-- as they are set, so there is nothing to snapshot up front.
-- @param modes string|string[] Unused, kept for compatibility
function KeymapManager:save(modes)
  vim.validate("modes", modes, { 'string', 'table', 'nil' })
  self.autocmd_group = vim.api.nvim_create_augroup(
    string.format('ViewportModeKeymaps_%s', self),
    { clear = true }
  )
end

-- Sets a buffer-local keymap, saving any mapping it replaces
function KeymapManager:_set_buffer_keymap(buf, mode, lhs, rhs, opts)
  self.replaced[buf] = self.replaced[buf] or {}
  self.replaced[buf][mode] = self.replaced[buf][mode] or {}
  local saved = self.replaced[buf][mode]
  if saved[lhs] == nil then
    saved[lhs] = get_buffer_mapping(buf, mode, lhs) or false
  end
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', opts or {}, { buffer = buf }))
end

-- Deletes all keymaps set by this manager and restores the buffer-local
-- mappings they replaced.
function KeymapManager:restore()
  -- Clear the autocmd group which also deletes all autocmds in it
  if self.autocmd_group then
    vim.api.nvim_del_augroup_by_id(self.autocmd_group)
    self.autocmd_group = nil
  end

  for buf, modes in pairs(self.replaced) do
    if vim.api.nvim_buf_is_valid(buf) then
      for mode, mappings in pairs(modes) do
        for lhs, original in pairs(mappings) do
          pcall(vim.api.nvim_buf_del_keymap, buf, mode, lhs)
          if original then
            -- mapset() always targets the current buffer
            vim.api.nvim_buf_call(buf, function()
              vim.fn.mapset(original)
            end)
          end
        end
      end
    end
  end

  self.keymaps = {}
  self.replaced = {}
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
      self:_set_buffer_keymap(buf, mode, lhs, rhs, opts)
    end
  end

  -- Create autocmd to set keymap on new buffers
  vim.api.nvim_create_autocmd('BufEnter', {
    group = self.autocmd_group,
    callback = function(ev)
      self:_set_buffer_keymap(ev.buf, mode, lhs, rhs, opts)
    end,
  })

  if not self.keymaps[mode] then
    self.keymaps[mode] = {}
  end

  table.insert(self.keymaps[mode], {
    lhs = lhs,
    rhs = rhs,
    opts = opts,
  })
end

-- Returns the keymaps set by this manager
-- @return table The keymaps set by this manager
function KeymapManager:get_keymaps()
  return self.keymaps
end

return M
