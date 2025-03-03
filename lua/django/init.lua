local M = {}

local function find_project_root()
  local current_path = vim.api.nvim_buf_get_name(0)
  current_path = current_path ~= '' and vim.fn.fnamemodify(current_path, ':p:h') or vim.loop.cwd()

  local path = current_path
  while true do
    local manage_py = path .. '/manage.py'
    if vim.loop.fs_stat(manage_py) then
      return path
    end
    local parent = vim.fn.fnamemodify(path, ':h')
    if parent == path then break end -- Reached filesystem root
    path = parent
  end
  return nil
end

local function find_settings_dir(project_root)
  local handle = vim.loop.fs_scandir(project_root)
  if not handle then return nil end

  while true do
    local name, typ = vim.loop.fs_scandir_next(handle)
    if not name then break end

    if typ == 'directory' then
      local candidate = project_root .. '/' .. name .. '/settings.py'
      if vim.loop.fs_stat(candidate) then
        return project_root .. '/' .. name
      end
    end
  end
  return nil
end

local function find_project_name()
  local project_root = find_project_root()
  if not project_root then
    vim.notify("Could not find Django project root (manage.py)", vim.log.levels.ERROR)
    return
  end

  local settings_dir = find_settings_dir(project_root)
  if not settings_dir then
    vim.notify("Could not find settings.py in project subdirectories", vim.log.levels.ERROR)
    return
  end

  return vim.fn.fnamemodify(settings_dir, ':t')
end

-- Default configuration
M.config = {
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
    migrations = "<C-d>", -- New keymap for migrations
  }
}

-- Function to validate mappings
local function validate_mappings(mappings)
  for key, value in pairs(mappings) do
    if type(value) ~= "string" then
      vim.notify("Invalid mapping for " .. key .. ": expected string, got " .. type(value), vim.log.levels.ERROR)
    end
  end
end

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

  -- Validate mappings to avoid nil errors
  if M.config.mappings then
    validate_mappings(M.config.mappings)
  end

  if M.config.keymaps then
    validate_mappings(M.config.keymaps)
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

  -- Set up key mappings safely with functions where needed
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
    vim.keymap.set("n", M.config.mappings.project_settings_file, function()
      vim.cmd("edit " .. tostring(find_project_name()) .. "/settings.py")
    end, { desc = "Project Settings" })
    vim.keymap.set("n", M.config.mappings.project_asgi_file, function()
      vim.cmd("edit " .. tostring(find_project_name()) .. "/asgi.py")
    end, { desc = "Project ASGI" })
    vim.keymap.set("n", M.config.mappings.project_wsgi_file, function()
      vim.cmd("edit " .. tostring(find_project_name()) .. "/wsgi.py")
    end, { desc = "Project WSGI" })
    vim.keymap.set("n", M.config.mappings.project_urls_file, function()
      vim.cmd("edit " .. tostring(find_project_name()) .. "/urls.py")
    end, { desc = "Project URLs" })
  end

  -- Print a success message
  vim.notify("Django.nvim configured successfully!", vim.log.levels.INFO)
end

function M.get_project_name()
  return find_project_name()
end

return M
