# django.nvim

A Neovim plugin for Django development that provides project navigation, command execution, and development tools.

![django.nvim](https://example.com/screenshot.png)

## Features

- **Django Management Commands**: Run any Django management command directly from Neovim
- **Project Navigation**:
  - Find and navigate URL patterns (routes)
  - Browse models with intelligent filtering
  - Search templates across your project
  - List and navigate between apps
- **Environment Support**: Virtual environment detection and activation
- **Intuitive Keymaps**: Consistent keyboard shortcuts for common Django operations

## Prerequisites

- Neovim 0.7+
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and its dependencies
- [ripgrep](https://github.com/BurntSushi/ripgrep) for code searching
- Optional but recommended:
  - [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) for virtual environment handling

## Installation

### Using packer.nvim

```lua
use {
  'username/django.nvim',
  requires = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim', -- telescope dependency
    -- Optional but recommended:
    'linux-cultist/venv-selector.nvim',
  }
}
```

### Using lazy.nvim

```lua
{
  'username/django.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    -- Optional but recommended:
    'linux-cultist/venv-selector.nvim',
  },
  config = function()
    require('django').setup({
      -- Your configuration here
    })
  end
}
```

## Configuration

```lua
require('django').setup({
  -- Path to manage.py (default: "manage.py")
  manage_py_path = "manage.py",
  
  -- Path to Django templates
  templates_path = "templates/",
  
  -- Default app to use for commands
  default_app = nil, -- e.g., "myapp"
  
  -- Auto-detect virtual environment
  auto_virtual_env = true,
  
  -- Custom virtual environment path
  virtual_env_path = nil, -- e.g., ".venv"
  
  -- Keymappings
  mappings =
