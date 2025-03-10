# django.nvim

A Neovim plugin for Django development that provides convenient navigation, commands, and utilities to streamline your Django workflow directly within Neovim.

## Features

- **Search and Navigate Django Apps**: Quickly find and navigate to your Django apps and their key files.
- **Execute Django Commands**: Run any `manage.py` command with a Telescope-powered interface.
- **Start New Django Projects**: Create new Django projects without leaving Neovim.
- **Django Shell Integration**: Open an interactive Django shell directly within Neovim.
- **Migrations Access**: Navigate directly to migrations directories for managing database changes.

## Requirements

- Neovim >= 0.7.0
- [Telescope](https://github.com/nvim-telescope/telescope.nvim) (optional but recommended)
- [vim-floaterm](https://github.com/voldikss/vim-floaterm) (optional but recommended)

## Installation

### Using packer.nvim

```lua
use {
  'username/django.nvim',
  requires = {
    {'nvim-telescope/telescope.nvim'},  -- Optional
    {'voldikss/vim-floaterm'},          -- Optional
  },
  config = function()
    require('django').setup()
  end
}
```

### Using vim-plug

```vim
Plug 'nvim-telescope/telescope.nvim'  " Optional
Plug 'voldikss/vim-floaterm'          " Optional
Plug 'username/django.nvim'
```

Then in your init.lua or vimrc:

```lua
require('django').setup()
```

## Configuration

```lua
require('django').setup({
  -- Default values for plugin configuration
  manage_py_path = nil, -- Will be detected automatically
  project_root = nil,   -- Will be detected automatically
  telescope_enabled = true,
  floaterm_enabled = true,
  mappings = {
    find_app = "<leader>df",
    run_command = "<leader>dd",
    django_shell = "<leader>dn",
    new_project = "<leader>dp",
    project_urls_file = "<leader>dsu",
    project_settings_file = "<leader>dss",
    project_asgi_file = "<leader>dsa",
    project_wsgi_file = "<leader>dsw",
  },
  -- Telescope keymaps for app navigation
  keymaps = {
    views = "<C-v>",
    models = "<C-m>",
    urls = "<C-u>",
    admin = "<C-a>",
    tests = "<C-t>",
    forms = "<C-f>",
    migrations = "<C-d>",
  }
})
```

## Commands

| Command                 | Description                                  |
|-------------------------|----------------------------------------------|
| `:DjangoFindApp`        | Find and navigate to a Django app            |
| `:DjangoCommand`        | Run a Django manage.py command               |
| `:DjangoShell`          | Open Django interactive shell                |
| `:DjangoNewProject`     | Create a new Django project                  |
| `:DjangoGoToViews`      | Navigate to views.py in Django apps          |
| `:DjangoGoToModels`     | Navigate to models.py in Django apps         |
| `:DjangoGoToUrls`       | Navigate to urls.py in Django apps           |
| `:DjangoGoToAdmin`      | Navigate to admin.py in Django apps          |
| `:DjangoGoToTests`      | Navigate to tests.py in Django apps          |
| `:DjangoGoToForms`      | Navigate to forms.py in Django apps          |
| `:DjangoGoToMigrations` | Navigate to migrations directory in apps     |

## Default Keymaps

| Keymap        | Command                  |
|---------------|--------------------------|
| `<leader>df`  | Find Django app          |
| `<leader>dc`  | Run Django command       |
| `<leader>ds`  | Open Django shell        |
| `<leader>dn`  | Create new Django project|

## App Navigation Keymaps

When using the app finder with Telescope, the following keymaps are available:

| Keymap   | Action                       |
|----------|------------------------------|
| `<enter>`| Open views.py (default)      |
| `<C-v>`  | Open views.py                |
| `<C-m>`  | Open models.py               |
| `<C-u>`  | Open urls.py                 |
| `<C-a>`  | Open admin.py                |
| `<C-t>`  | Open tests.py                |
| `<C-f>`  | Open forms.py                |
| `<C-d>`  | Open migrations directory    |

## Customizing Telescope Navigation Keymaps

You can customize the keymaps used within Telescope for navigating to different Django app files:

```lua
require('django').setup({
  keymaps = {
    views = "<C-v>",      -- Change key for views.py navigation
    models = "<C-o>",     -- Change key for models.py navigation  
    migrations = "<C-g>", -- Change key for migrations directory
    -- Configure other keymaps as needed
  }
})
```


## Usage Examples

### Finding and Navigating to Apps

```vim
:DjangoFindApp
```

This opens a Telescope finder with all Django apps in your project. Press Enter to open the views.py file of the selected app (default behavior), or use the custom keymaps to open other app files.

### Running Django Commands

```vim
:DjangoCommand
```

This opens a Telescope finder with all available Django commands. Select a command to run it. For commands that require additional arguments (like `runserver` or `startapp`), you will be prompted to enter them.

### Opening Django Shell

```vim
:DjangoShell
```

Opens an interactive Django shell using Python's shell.

### Creating a New Django Project

```vim
:DjangoNewProject my_project
```

Creates a new Django project named "my_project" and changes the current directory to it.

### Navigating to Migrations

```vim
:DjangoGoToMigrations
```

Opens a Telescope finder with apps that have migrations directories. Select an app to open its migrations directory.

Alternatively, when in the app finder, press `<C-d>` to navigate directly to the selected app's migrations directory.
