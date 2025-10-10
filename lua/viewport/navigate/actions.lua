local window = require('viewport.window')
local mode = require('viewport.mode')

local actions = {}

local function focus_window(direction)
  local current_window = window.new()
  local neighbor = current_window:neighbor(direction)
  if neighbor then
    neighbor:focus()
    return true
  end
  return false
end

local function move_window(direction)
  local current_window = window.new()
  -- TODO: Do we need to check if the move is valid?
  current_window:move(direction)
end

local function swap_window(direction)
  local current_window = window.new()
  return current_window:swap(direction)
end

function actions.focus_above()
  focus_window("up")
end

function actions.focus_below()
  focus_window("down")
end

function actions.focus_left()
  focus_window("left")
end

function actions.focus_right()
  focus_window("right")
end

function actions.move_up()
  move_window("up")
end

function actions.move_down()
  move_window("down")
end

function actions.move_left()
  move_window("left")
end

function actions.move_right()
  move_window("right")
end

function actions.swap_above()
  if swap_window("up") then
    focus_window("up")
  end
end

function actions.swap_below()
  if swap_window("down") then
    focus_window("down")
  end
end

function actions.swap_left()
  if swap_window("left") then
    focus_window("left")
  end
end

function actions.swap_right()
  if swap_window("right") then
    focus_window("right")
  end
end

local select_choices_default_opts = {
  -- Use letters a-z to select windows
  choices = vim.split('abcdefghijklmnopqrstuvwxyz', ''),
  horizontal_padding = 4,
}

function actions.select_mode(opts)
  opts = vim.tbl_extend('keep', opts or {}, select_choices_default_opts)
  local windows = window.list_tab()
  local keymaps = {}
  local popups = {}
  if #windows > #opts.choices then
    error("Too many windows to select from. Max is " .. #opts.choices)
  end
  for i, win in ipairs(windows) do
    -- Create a popup above each window with one of the choices
    local buf = vim.api.nvim_create_buf(false, true)
    local choice = opts.choices[i]
    local text = "[" .. choice .. "]"
    local width = #text + opts.horizontal_padding
    -- Insert the text in the middle of the buffer
    text = string.rep(" ", math.floor((width - #text) / 2)) .. text
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
    local popup = window.open({
      bufnr = buf,
      config = {
        relative = 'win',
        win = win.id,
        style = 'minimal',
        -- position in the middle of the window
        row = win:height() / 2,
        col = win:width() / 2,
        width = width,
        height = 1,
        title = "select",
        footer = "window",
        title_pos = "center",
        footer_pos = "center",
        noautocmd = true,
        border = 'rounded',
      }
    })
    -- Track popups so we can close them later
    table.insert(popups, popup)
    -- Configure the a mapping for this choice to focus the window
    keymaps[choice] = function()
      win:focus()
      -- Tell the mode to stop after this action
      return true
    end
  end

  -- TODO: Find a way to disable other mappings and log a warning
  mode.new({
    mappings = keymaps,
    mapping_opts = { nowait = true },
    post_stop = function()
      -- Close all popups
      for _, popup in ipairs(popups) do
        -- Delete the temporary buffer, which also closes the window
        popup:delete_buffer()
      end
    end
  }):start()
end

return actions
