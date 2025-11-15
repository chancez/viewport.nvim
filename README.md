# viewport.nvim

A modal window management plugin for Neovim that provides intuitive modes for resizing, navigating, and manipulating windows.

## Features

- **Resize Mode**: Interactively resize windows with directional keys
- **Navigate Mode**: Navigate and swap windows with vim-like keybindings
- **Select Mode**: Choose windows and perform actions on them
- **Swap Mode**: Swap the current window with another selected window
- **Preset Keymaps**: Pre-configured keybindings for common workflows
- **Extensible**: Customize mappings and actions to fit your workflow

## Showcase

[![asciicast](https://asciinema.org/a/D8fLp5dQZyG0WHbj6vKSikQof.svg)](https://asciinema.org/a/D8fLp5dQZyG0WHbj6vKSikQof)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "chancez/viewport.nvim",
  config = function()
    require('viewport').setup()
  end,
}
```

## Configuration

### Basic Setup

```lua
require('viewport').setup({
  resize_mode = {
    resize_amount = 5,  -- Amount to resize by (default: 1)
    mappings = {
      preset = 'relative',  -- 'absolute' or 'relative'. Set to 'none' to disable preset mappings.
    },
    display_mappings = true,  -- Show available mappings (default: true)
  },
  navigate_mode = {
    mappings = {
      preset = 'default',
    },
    display_mappings = true,
  },
  select_mode = {
    -- Customize actions available in select mode
    choices = {
      {
        key = 'f',
        text = "[f]ocus",
        action = function(win)
          win:focus()
        end
      },
      -- Add more custom choices...
    }
  }
})
```

### Example Configuration

Partially taken from my [dotfiles](https://github.com/chancez/dotfiles/blob/master/neovim/.config/nvim/lua/plugins/viewport.lua):

```lua
return {
  "chancez/viewport.nvim",
  keys   = {
    { '<leader>R',    function() require('viewport').start_resize_mode() end,       desc = 'Start resize mode' },
    { '<leader>N',    function() require('viewport').start_navigate_mode() end,     desc = 'Start navigate mode' },
    { '<leader>S',    function() require('viewport').start_select_mode() end,       desc = 'Start select mode' },
    { '<leader>sel',  function() require('viewport.actions').select_window() end,   desc = 'Select a window to focus' },
    { '<leader>swap', function() require('viewport').start_swap_mode() end,         desc = 'Select a window to swap with the current window' },
    { '<c-w>0',       function() require('viewport.actions').toggle_maximize() end, desc = 'Toggle maximize current window' },
  },
  cmd    = {
    "ResizeMode",
    "NavigateMode",
  },
  config = function()
    local viewport = require('viewport')
    viewport.setup({
      resize_mode = {
        resize_amount = 5,
        mappings = {
          preset = 'relative',
        },
      }
    })

    -- Refresh lualine on viewport mode changes
    local grp = vim.api.nvim_create_augroup("viewport", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = grp,
      pattern = viewport.modes.mode_change_autocmd,
      callback = function()
        require('lualine').refresh()
      end,
    })

    vim.api.nvim_create_user_command('ResizeMode', function()
      viewport.start_resize_mode()
    end, { desc = 'Start resize mode' })

    vim.api.nvim_create_user_command('NavigateMode', function()
      viewport.start_navigate_mode()
    end, { desc = 'Start navigate mode' })
  end,
}
```

## Usage

### Modes

#### Resize Mode

Start resize mode to interactively adjust window sizes:

```lua
require('viewport').start_resize_mode()
```

**Default keybindings (absolute preset):**
- `h` - Resize left
- `j` - Resize down
- `k` - Resize up
- `l` - Resize right
- `<Esc>` - Exit resize mode

**Relative preset:**
Resizes relative to the current window's position (recommended for more intuitive resizing).

#### Navigate Mode

Start navigate mode to move between windows and swap them:

```lua
require('viewport').start_navigate_mode()
```

**Default keybindings:**
- `h/j/k/l` - Focus window in direction
- `H/J/K/L` - Swap with window in direction
- `s` - Select a window
- `<Esc>` - Exit navigate mode

#### Select Mode

Start select mode to choose a window and perform an action:

```lua
require('viewport').start_select_mode()
```

**Default actions:**
- `r` - Resize the selected window
- `f` - Focus the selected window
- `s` - Swap with the selected window
- `c` - Close the selected window
- `h` - Horizontal split
- `v` - Vertical split

#### Swap Mode

Start swap mode to swap the current window with another:

```lua
require('viewport').start_swap_mode()
```

### User Commands

You can also create user commands for convenience:

```lua
vim.api.nvim_create_user_command('ResizeMode', function()
  require('viewport').start_resize_mode()
end, { desc = 'Start resize mode' })

vim.api.nvim_create_user_command('NavigateMode', function()
  require('viewport').start_navigate_mode()
end, { desc = 'Start navigate mode' })
```

### Integration with Status Lines

The active mode is available in `vim.g.viewport_active_mode`, which can be used in your status line.

For example, using Lualine:

```lua
{
    'nvim-lualine/lualine.nvim',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    opts = {
      sections = {
        lualine_a = { 'mode', 'g:viewport_active_mode' }
      }
    }
}
```

viewport.nvim also emits a `User` autocmd when modes change.
You can use this to trigger your status line to update:

```lua
local grp = vim.api.nvim_create_augroup("viewport", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = grp,
  pattern = require('viewport').mode_change_autocmd,
  callback = function()
    require('lualine').refresh()
  end,
})
```

## Advanced Configuration

### Custom Keybindings

You can override the preset mappings with your own:

```lua
require('viewport').setup({
  resize_mode = {
    mappings = {
      preset = 'relative',
      n = {
        h = false, -- Set default mappings to false to disable them.
        j = false,
        ['<C-h>'] = require('viewport.actions.resize').relative_resize_left,
        ['<C-j>'] = require('viewport.actions.resize').relative_resize_down,
        -- Add more custom mappings...
      },
    },
  },
})
```

### Available Actions

Actions can be accessed via `require('viewport.actions')`:

- **Resize**: `resize_up`, `resize_down`, `resize_left`, `resize_right`, `relative_resize_*`
- **Focus**: `focus_above`, `focus_below`, `focus_left`, `focus_right`
- **Swap**: `swap_above`, `swap_below`, `swap_left`, `swap_right`
- **Select**: `select_window`
