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
      action = function(win)
        win:focus()
        require('viewport.modes').start('resize')
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
        require('viewport.modes').start('swap')
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
  }
}

return default_config
