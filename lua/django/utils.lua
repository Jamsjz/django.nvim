-- lua/django/utils.lua
-- Utility functions for the Django plugin

local M = {}

-- Find the root directory of a Django project
-- Searches for manage.py in current or parent directories
function M.find_django_root()
  local current_dir = vim.fn.getcwd()
  local max_depth = 5 -- Don't go up more than 5 levels

  for i = 0, max_depth do
    local check_path = current_dir
    if i > 0 then
      check_path = vim.fn.fnamemodify(current_dir, ":h" .. string.rep(":h", i - 1))
    end

    local manage_py = check_path .. "/manage.py"
    if vim.fn.filereadable(manage_py) == 1 then
      return check_path
    end
  end

  return nil
end

-- Find all Django apps in the project
function M.find_django_apps(project_root)
  -- If no project root provided, try to find it
  if not project_root then
    project_root = M.find_django_root()
  end

  if not project_root then
    vim.notify("Could not find Django project root", vim.log.levels.ERROR)
    return {}
  end

  local apps = {}

  -- Helper function to check if a directory is a Django app
  local function is_django_app(dir)
    -- Check if directory contains apps.py or models.py
    return vim.fn.filereadable(dir .. "/apps.py") == 1 or
        vim.fn.filereadable(dir .. "/models.py") == 1
  end

  -- Helper function to scan a directory for potential Django apps
  local function scan_dir(dir)
    -- Get all directories in the specified directory
    local handle = vim.loop.fs_scandir(dir)
    if not handle then return end

    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then break end

      local full_path = dir .. "/" .. name
      if type == "directory" and not name:match("^%.") then
        -- Skip hidden directories
        if is_django_app(full_path) then
          table.insert(apps, {
            name = name,
            path = full_path,
            full_path = full_path,
            is_app = true
          })
        end

        -- Also scan subdirectories (for nested apps)
        scan_dir(full_path)
      end
    end
  end

  -- Start scanning from project root
  scan_dir(project_root)

  return apps
end

-- Run a shell command and capture its output
function M.run_command(cmd)
  local result = vim.fn.system(cmd)
  return result
end

-- Get all available Django commands
function M.get_django_commands(manage_py_path)
  if not manage_py_path or vim.fn.filereadable(manage_py_path) ~= 1 then
    vim.notify("manage.py not found", vim.log.levels.ERROR)
    return {}
  end

  local cmd = manage_py_path .. " help --commands"
  local output = M.run_command(cmd)

  -- Parse the output to get a list of commands
  local commands = {}
  for line in output:gmatch("[^\r\n]+") do
    if line and line ~= "" then
      table.insert(commands, {
        name = line,
        full_command = manage_py_path .. " " .. line
      })
    end
  end

  return commands
end

-- Check if a required plugin is available
function M.has_plugin(plugin)
  local has_plugin = vim.fn.exists("g:loaded_" .. plugin) == 1 or
      vim.fn.exists("g:loaded_" .. plugin .. ".nvim") == 1

  -- Special check for telescope
  if plugin == "telescope" then
    has_plugin = has_plugin or pcall(require, "telescope")
  elseif plugin == "floaterm" then
    has_plugin = has_plugin or vim.fn.exists("g:loaded_floaterm") == 1
  end

  return has_plugin
end

return M
