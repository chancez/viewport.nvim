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

default_config.select_mode = {
  choices = {
    {
      key = 'r',
      text = "[r]esize",
      action = function(_, win)
        win:focus()
        -- Need a wait to wait for the mode to stop so the parent mode can know the action "completed"
        require('viewport.mode.registry').start('resize')
      end
    },
    {
      key = 'f',
      text = "[f]ocus",
      action = function(_, win)
        win:focus()
      end
    },
    {
      key = 's',
      text = "[s]wap",
      action = function(_, win)
        win:focus()
        require('viewport.mode.registry').start('swap')
      end
    },
    {
      key = 'c',
      text = "[c]lose",
      action = function(_, win)
        win:close()
      end
    },
    {
      key = 'o',
      text = "[o]nly",
      action = function(_, win)
        win:focus()
        vim.cmd('only')
      end
    },
    {
      key = 'h',
      text = "[h]orizontal split",
      action = function(_, win)
        win:split_horizontal(true)
      end
    },
    {
      key = 'v',
      text = "[v]ertical split",
      action = function(_, win)
        win:split_vertical(true)
      end
    },
    {
      key = 'm',
      text = "[m]aximize",
      action = function(_, win)
        win:focus()
        require('viewport.actions.zoom').maximize()
      end
    },
    {
      key = '<Esc>',
      text = '[Esc] - stop',
      action = function(mode, _)
        mode:stop()
      end,
    },
  }
}

return default_config
