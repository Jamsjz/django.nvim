-- lua/django/init.lua
-- Main entry point for the Django Neovim plugin

local M = {}

-- Default configuration
M.config = {
  -- Default values for plugin configuration
  manage_py_path = nil, -- Will be detected automatically
  project_root = nil,   -- Will be detected automatically
  telescope_enabled = true,
  floaterm_enabled = true,
  mappings = {
    find_app = "<leader>df",
    run_command = "<leader>dc",
    django_shell = "<leader>ds",
    new_project = "<leader>dn",
  },
  -- Telescope keymaps for app navigation
  keymaps = {
    views = "<C-v>",
    models = "<C-m>",
    urls = "<C-u>",
    admin = "<C-a>",
    tests = "<C-t>",
    forms = "<C-f>",
    migrations = "<C-d>", -- New keymap for migrations
  }
}

-- Setup function to initialize the plugin with user configuration
function M.setup(opts)
  -- Merge user config with defaults
  if opts then
    for k, v in pairs(opts) do
      if k == "keymaps" and type(v) == "table" then
        M.config.keymaps = vim.tbl_extend("force", M.config.keymaps, v)
      else
        M.config[k] = v
      end
    end
  end

  -- Load dependencies
  local commands = require("django.commands")
  local navigation = require("django.navigation")
  local utils = require("django.utils")

  -- Try to detect Django project automatically
  if not M.config.project_root then
    M.config.project_root = utils.find_django_root()
  end

  if not M.config.manage_py_path and M.config.project_root then
    M.config.manage_py_path = M.config.project_root .. "/manage.py"
  end

  -- Set up commands and navigation
  commands.setup(M.config)
  navigation.setup(M.config)

  -- Create user commands
  vim.api.nvim_create_user_command("DjangoFindApp", function()
    navigation.find_app()
  end, { desc = "Find and navigate to a Django app" })

  vim.api.nvim_create_user_command("DjangoCommand", function()
    commands.run_command()
  end, { desc = "Run a Django manage.py command" })

  vim.api.nvim_create_user_command("DjangoShell", function()
    commands.open_shell()
  end, { desc = "Open Django interactive shell" })

  vim.api.nvim_create_user_command("DjangoNewProject", function(opts)
    commands.new_project(opts.args)
  end, { nargs = 1, desc = "Create a new Django project" })

  -- Add explicit commands for file navigation
  vim.api.nvim_create_user_command("DjangoGoToViews", function()
    navigation.goto_django_file("views")
  end, { desc = "Navigate to views.py in Django apps" })

  vim.api.nvim_create_user_command("DjangoGoToModels", function()
    navigation.goto_django_file("models")
  end, { desc = "Navigate to models.py in Django apps" })

  vim.api.nvim_create_user_command("DjangoGoToUrls", function()
    navigation.goto_django_file("urls")
  end, { desc = "Navigate to urls.py in Django apps" })

  vim.api.nvim_create_user_command("DjangoGoToAdmin", function()
    navigation.goto_django_file("admin")
  end, { desc = "Navigate to admin.py in Django apps" })

  vim.api.nvim_create_user_command("DjangoGoToTests", function()
    navigation.goto_django_file("tests")
  end, { desc = "Navigate to tests.py in Django apps" })

  vim.api.nvim_create_user_command("DjangoGoToForms", function()
    navigation.goto_django_file("forms")
  end, { desc = "Navigate to forms.py in Django apps" })

  -- Add new command for migrations directory
  vim.api.nvim_create_user_command("DjangoGoToMigrations", function()
    navigation.goto_django_file("migrations")
  end, { desc = "Navigate to migrations directory in Django apps" })

  -- Set up key mappings if not explicitly disabled
  if M.config.mappings then
    vim.keymap.set('n', M.config.mappings.find_app, function() navigation.find_app() end, { desc = "Find Django app" })
    vim.keymap.set('n', M.config.mappings.run_command, function() commands.run_command() end,
      { desc = "Run Django command" })
    vim.keymap.set('n', M.config.mappings.django_shell, function() commands.open_shell() end,
      { desc = "Open Django shell" })
    vim.keymap.set('n', M.config.mappings.new_project, function()
      vim.ui.input({ prompt = "Project name: " }, function(name)
        if name then commands.new_project(name) end
      end)
    end, { desc = "Create new Django project" })
  end

  -- Print a success message
  vim.notify("Django.nvim loaded successfully" .. (M.config.project_root and " (Django project detected)" or ""),
    vim.log.levels.INFO)
end

return M
