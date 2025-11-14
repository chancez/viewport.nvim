local action = require('viewport.action')

local zoom_actions = {}

-- Maximizes the current window by resizing it to fill the available space
zoom_actions.maximize = function()
  vim.t.viewport_zoom_before = vim.fn.winrestcmd()
  vim.cmd.resize({ mods = { vertical = true } })
  vim.cmd.resize()
end

-- Restores the window to its previous size before maximization
zoom_actions.restore = function()
  if vim.t.viewport_zoom_before then
    vim.cmd(vim.t.viewport_zoom_before)
    vim.t.viewport_zoom_before = nil
  else
    -- Fallback: equalize all windows if no previous state is stored
    vim.cmd("wincmd =")
  end
end

-- Toggles between maximizing the current window and restoring it to its previous size
zoom_actions.toggle_maximize = function()
  if vim.t.viewport_zoom_before then
    zoom_actions.restore()
  else
    zoom_actions.maximize()
  end
end

return action.from_module(zoom_actions)
