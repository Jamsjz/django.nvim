-- django.nvim - Main module
-- A Neovim plugin for Django development

local M = {}

-- Import submodules
local commands = require("django.commands")
local navigation = require("django.navigation")
local terminal = require("django.terminal")
local utils = require("django.utils")

-- Setup function
M.setup = function(opts)
  -- Initialize with default options
  local default_opts = {
    -- Path to manage.py
    manage_py_path = "manage.py",

    -- Path to Django templates
    templates_path = "templates/",

    -- Default app to use for commands
    default_app = nil,

    -- Terminal settings
    terminal = {
      position = "horizontal", -- horizontal, vertical, float
      size = 15,
    },

    -- Enable terminal toggle
    enable_terminal_toggle = true,

    -- Auto-detect virtual environment
    auto_virtual_env = true,

    -- Custom virtual environment path
    virtual_env_path = nil,

    -- Keymappings
    mappings = {
      enabled = true,
      prefix = "<Leader>d",
    },
  }

  -- Merge default options with user options
  M.options = vim.tbl_deep_extend("force", default_opts, opts or {})

  -- Check if this is a Django project
  if not utils.is_django_project(M.options.manage_py_path) then
    vim.notify("Django project not detected. Some features may not work.", vim.log.levels.WARN)
  end

  -- Auto-detect virtual environment if enabled
  if M.options.auto_virtual_env and not M.options.virtual_env_path then
    M.options.virtual_env_path = utils.detect_venv()
  end

  -- Initialize submodules
  commands.setup(M.options)
  navigation.setup(M.options)
  terminal.setup(M.options)

  -- Register commands
  M.register_commands()

  -- Set up autocommands for Django files
  M.setup_autocmds()
end

-- Register plugin commands
M.register_commands = function()
  vim.api.nvim_create_user_command("Django", function(args)
    commands.run_command(args.args)
  end, { nargs = "*", desc = "Run Django management command" })

  vim.api.nvim_create_user_command("DjangoRoutes", function()
    navigation.find_routes()
  end, { desc = "Find Django URL patterns" })

  vim.api.nvim_create_user_command("DjangoModels", function()
    navigation.find_models()
  end, { desc = "Find Django models" })

  vim.api.nvim_create_user_command("DjangoTemplates", function()
    navigation.find_templates()
  end, { desc = "Find Django templates" })

  vim.api.nvim_create_user_command("DjangoApps", function()
    navigation.list_apps()
  end, { desc = "List Django apps" })

  vim.api.nvim_create_user_command("DjangoVenv", function()
    terminal.activate_venv()
  end, { desc = "Activate Django virtual environment" })
end

-- Setup autocommands for Django files
M.setup_autocmds = function()
  if not M.options.mappings.enabled then
    return
  end

  vim.api.nvim_create_augroup("django_nvim", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = "django_nvim",
    pattern = { "python", "html", "htmldjango" },
    callback = function()
      -- Only set up if we're in a Django project
      if not utils.is_django_project(M.options.manage_py_path) then
        return
      end

      local prefix = M.options.mappings.prefix
      local opts = { noremap = true, silent = true, buffer = true }

      -- Main commands
      vim.keymap.set("n", prefix .. "j", ":Django<CR>", opts)
      vim.keymap.set("n", prefix .. "r", ":DjangoRoutes<CR>", opts)
      vim.keymap.set("n", prefix .. "m", ":DjangoModels<CR>", opts)
      vim.keymap.set("n", prefix .. "t", ":DjangoTemplates<CR>", opts)
      vim.keymap.set("n", prefix .. "a", ":DjangoApps<CR>", opts)
      vim.keymap.set("n", prefix .. "v", ":DjangoVenv<CR>", opts)

      -- Shortcuts for common commands
      vim.keymap.set("n", prefix .. "rs", ":Django runserver<CR>", opts)
      vim.keymap.set("n", prefix .. "sh", ":Django shell<CR>", opts)
      vim.keymap.set("n", prefix .. "mi", ":Django migrate<CR>", opts)
      vim.keymap.set("n", prefix .. "mm", ":Django makemigrations<CR>", opts)
      vim.keymap.set("n", prefix .. "te", ":Django test<CR>", opts)

      -- Terminal toggle
      if M.options.enable_terminal_toggle then
        vim.keymap.set("n", prefix .. "tt", function() terminal.toggle_term() end, opts)
      end
    end,
  })
end

-- Export public functions
M.run_django_command = commands.run_command
M.list_management_commands = commands.list_commands
M.find_routes = navigation.find_routes
M.find_models = navigation.find_models
M.find_templates = navigation.find_templates
M.list_apps = navigation.list_apps
M.toggle_term = terminal.toggle_term
M.activate_venv = terminal.activate_venv
M.is_django_project = utils.is_django_project

return M
