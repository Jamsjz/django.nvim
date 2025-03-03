-- lua/django/commands.lua
-- Django command execution functionality

local M = {}
local config = {}

-- Initialize commands module
function M.setup(opts)
  config = opts
end

-- Run a Django management command
function M.run_command()
  local utils = require("django.utils")

  if not config.manage_py_path or vim.fn.filereadable(config.manage_py_path) ~= 1 then
    vim.notify("manage.py not found. Please set manage_py_path in configuration", vim.log.levels.ERROR)
    return
  end

  -- Get available Django commands
  local commands = utils.get_django_commands(config.manage_py_path)

  if #commands == 0 then
    vim.notify("No Django commands found", vim.log.levels.WARN)
    return
  end

  -- Use telescope if available
  if config.telescope_enabled and utils.has_plugin("telescope") then
    local telescope = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    pickers.new({}, {
      prompt_title = "Django Commands",
      finder = finders.new_table({
        results = commands,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            local command = selection.value.name

            -- Some commands need additional arguments
            if command == "runserver" or command == "makemigrations" or
                command == "migrate" or command == "createsuperuser" or
                command == "startapp" or command == "test" or
                command == "dbshell" then
              vim.ui.input({ prompt = "Additional arguments for " .. command .. ":" }, function(args)
                if args ~= nil then
                  M.execute_command(command, args)
                end
              end)
            else
              M.execute_command(command, "")
            end
          end
        end)

        return true
      end,
    }):find()
  else
    -- Fallback to vim.ui.select
    local items = {}
    for _, cmd in ipairs(commands) do
      table.insert(items, cmd.name)
    end

    vim.ui.select(items, {
      prompt = "Select Django command to run:",
    }, function(choice)
      if not choice then return end

      -- Check if the command needs additional arguments
      if choice == "runserver" or choice == "makemigrations" or
          choice == "migrate" or choice == "createsuperuser" or
          choice == "startapp" or choice == "test" or
          choice == "dbshell" or choice == "sqlmigrate" then
        vim.ui.input({ prompt = "Additional arguments for " .. choice .. ":" }, function(args)
          if args ~= nil then
            M.execute_command(choice, args)
          end
        end)
      else
        M.execute_command(choice, "")
      end
    end)
  end
end

-- Execute a Django command
function M.execute_command(command, args)
  if not config.manage_py_path then
    vim.notify("manage.py path not set", vim.log.levels.ERROR)
    return
  end

  -- Build the command string
  local cmd = config.manage_py_path .. " " .. command
  if args and args ~= "" then
    cmd = cmd .. " " .. args
  end

  -- Check if we should use floaterm if available
  if config.floaterm_enabled and vim.fn.exists("g:loaded_floaterm") == 1 then
    cmd = "FloatermNew --autoclose=0 " .. cmd
    vim.cmd(cmd)
  else
    -- Fallback to terminal
    vim.cmd("terminal " .. cmd)
    vim.cmd("startinsert")
  end
end

-- Open Django shell
function M.open_shell()
  if not config.manage_py_path then
    vim.notify("manage.py path not set", vim.log.levels.ERROR)
    return
  end

  local cmd = config.manage_py_path .. " shell"

  -- Use floaterm if available
  if config.floaterm_enabled and vim.fn.exists("g:loaded_floaterm") == 1 then
    vim.cmd("FloatermNew --autoclose=0 " .. cmd)
  else
    -- Fallback to terminal
    vim.cmd("terminal " .. cmd)
    vim.cmd("startinsert")
  end
end

-- Create a new Django project
function M.new_project(project_name)
  if not project_name or project_name == "" then
    vim.notify("Project name is required", vim.log.levels.ERROR)
    return
  end

  -- Create a command to create a new Django project
  local cmd = "django-admin startproject " .. project_name

  -- Use floaterm if available
  if config.floaterm_enabled and vim.fn.exists("g:loaded_floaterm") == 1 then
    vim.cmd("FloatermNew --autoclose=1 " .. cmd)

    -- After project creation, change directory and update config
    vim.defer_fn(function()
      local new_dir = vim.fn.getcwd() .. "/" .. project_name
      vim.cmd("cd " .. new_dir)
      config.project_root = new_dir
      config.manage_py_path = new_dir .. "/manage.py"
      vim.notify("Django project created and directory changed to " .. new_dir, vim.log.levels.INFO)
    end, 1000)
  else
    -- Fallback to system command
    local result = vim.fn.system(cmd)

    if vim.v.shell_error == 0 then
      local new_dir = vim.fn.getcwd() .. "/" .. project_name
      vim.cmd("cd " .. new_dir)
      config.project_root = new_dir
      config.manage_py_path = new_dir .. "/manage.py"
      vim.notify("Django project created and directory changed to " .. new_dir, vim.log.levels.INFO)
    else
      vim.notify("Error creating Django project: " .. result, vim.log.levels.ERROR)
    end
  end
end

return M
