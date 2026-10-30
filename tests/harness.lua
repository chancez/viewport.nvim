-- Minimal headless test runner.
-- Usage: nvim --headless --clean -l tests/harness.lua tests/foo_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.rtp:prepend(root)

local function reset()
  for name in pairs(package.loaded) do
    if name:match('^viewport') then
      package.loaded[name] = nil
    end
  end
  vim.cmd('silent! only!')
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= vim.api.nvim_get_current_buf() then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  vim.cmd('silent! mapclear | silent! mapclear <buffer>')
  vim.g.viewport_active_mode = nil
end

local failed = 0
for _, path in ipairs(arg) do
  local spec = dofile(path)
  local names = vim.tbl_keys(spec)
  table.sort(names)
  for _, name in ipairs(names) do
    reset()
    local ok, err = xpcall(spec[name], debug.traceback)
    if ok then
      io.write('ok   ' .. name .. '\n')
    else
      failed = failed + 1
      io.write('FAIL ' .. name .. '\n' .. err .. '\n')
    end
  end
end
os.exit(failed == 0 and 0 or 1)
