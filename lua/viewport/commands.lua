-- Handlers for user commands. viewport does not create commands itself, so
-- you can name them as you like. For example:
--
--   local layout_cmd = require('viewport.commands').layout
--   vim.api.nvim_create_user_command('ViewportLayout', layout_cmd.run, {
--     nargs = '?',
--     complete = layout_cmd.complete,
--   })
local commands = {}

commands.layout = {}

-- Sets the layout named in opts.args on the current tabpage. 'none' clears
-- the layout, and no argument opens the layout picker.
-- @param opts table The table passed to nvim_create_user_command() callbacks
function commands.layout.run(opts)
  local viewport = require('viewport')
  local name = vim.trim(opts and opts.args or '')
  if name == '' then
    viewport.pick_layout()
  elseif name == 'none' then
    viewport.set_layout(nil)
  elseif vim.tbl_contains(viewport.layouts:names(), name) then
    viewport.set_layout(name)
  else
    vim.notify(string.format("viewport: unknown layout '%s'", name), vim.log.levels.ERROR)
  end
end

-- Completes layout names, plus 'none'
-- @param arglead string The text being completed
-- @return string[] Matching names
function commands.layout.complete(arglead)
  local names = vim.list_extend(require('viewport').layouts:names(), { 'none' })
  return vim.tbl_filter(function(name)
    return vim.startswith(name, arglead)
  end, names)
end

return commands
