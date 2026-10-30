-- Default configuration for the viewport plugin
-- @type Config
local default_config = {}

default_config.resize_mode = {
  resize_amount = 1,
  mappings = {
    preset = 'absolute', -- 'absolute' or 'relative'
  },
  display_mappings = true,
}

default_config.navigate_mode = {
  mappings = {
    preset = 'default',
  },
  display_mappings = true,
}

default_config.layout = {
  -- Fraction of the tab given to the main window in the tall and fat layouts
  main_ratio = 0.5,
  -- Extra layouts by name. Each is a function(wins, opts) that arranges a
  -- list of window ids, main window first. See viewport.layout.arrange.
  layouts = {},
  -- Function taking a window id that returns true to leave the window out of
  -- layouts. Defaults to excluding floats and special buffers like help and
  -- quickfix.
  should_exclude_window = nil,
}

default_config.select_mode = {
  choices = {
    {
      key = 'r',
      text = "[r]esize",
      action = function(win)
        win:focus()
        require('viewport').start_resize_mode()
      end
    },
    {
      key = 'f',
      text = "[f]ocus",
      action = function(win)
        win:focus()
      end
    },
    {
      key = 's',
      text = "[s]wap",
      action = function(win)
        win:focus()
        require('viewport').start_swap_mode()
      end
    },
    {
      key = 'c',
      text = "[c]lose",
      action = function(win)
        win:close()
      end
    },
    {
      key = 'o',
      text = "[o]nly",
      action = function(win)
        win:focus()
        vim.cmd('only')
      end
    },
    {
      key = 'h',
      text = "[h]orizontal split",
      action = function(win)
        win:split_horizontal(true)
      end
    },
    {
      key = 'v',
      text = "[v]ertical split",
      action = function(win)
        win:split_vertical(true)
      end
    },
    {
      key = 'm',
      text = "[m]aximize",
      action = function(win)
        win:focus()
        require('viewport.actions.zoom').maximize()
      end
    },
  }
}

return default_config
