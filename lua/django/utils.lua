-- django.nvim - Utilities module
-- Helper functions for the plugin

local M = {}

-- Check if current directory is a Django project
M.is_django_project = function(manage_py_path)
  return vim.fn.filereadable(manage_py_path) == 1
end

-- Detect virtual environment
M.detect_venv = function()
  -- Common virtual environment directories
  local venv_paths = {
    ".venv",
    "venv",
    "env",
    ".env",
    "virtualenv",
  }

  for _, path in ipairs(venv_paths) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end

  return nil
end

-- Find Django project root
M.find_project_root = function()
  -- Start from the current directory and look for manage.py
  local current_dir = vim.fn.getcwd()
  local max_depth = 5 -- Limit the search depth

  local dir = current_dir
  for i = 1, max_depth do
    if vim.fn.filereadable(dir .. "/manage.py") == 1 then
      return dir
    end

    -- Move up one directory
    dir = vim.fn.fnamemodify(dir, ":h")

    -- Stop if we've reached the root
    if dir == "/" or dir:match("^%a:[/\\]$") then
      break
    end
  end

  return current_dir -- Default to current directory if not found
end

-- Get current Django app name from the file path
M.get_current_app = function(filepath)
  if not filepath then
    filepath = vim.fn.expand("%:p")
  end

  -- Extract app name from file path, assuming standard Django project structure
  local app_pattern = ".+/([^/]+)/[^/]+%.py$"
  return filepath:match(app_pattern)
end

-- Parse Django settings module from manage.py
M.get_django_settings_module = function(manage_py_path)
  if not M.is_django_project(manage_py_path) then
    return nil
  end

  local handle = io.open(manage_py_path, "r")
  if not handle then
    return nil
  end

  local content = handle:read("*all")
  handle:close()

  -- Look for the DJANGO_SETTINGS_MODULE environment variable
  local settings_module = content:match("os%.environ%.setdefault%(\"DJANGO_SETTINGS_MODULE\"%s*,%s*[\"']([^\"']+)[\"']")

  return settings_module
end

return M
