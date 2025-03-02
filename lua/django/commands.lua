-- django.nvim - Commands module
-- Handles Django management command execution

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}
local options = {}

-- Setup function
M.setup = function(opts)
  options = opts
end

-- Run Django management command
M.run_command = function(command)
  if command == "" then
    -- Show available commands if none specified
    M.list_commands()
    return
  end

  local full_command = "python " .. options.manage_py_path .. " " .. command
  vim.cmd("!" .. full_command)
end

-- Get list of Django management commands
local function get_django_commands()
  local django_commands = {
    "runserver", "shell", "test", "migrate", "makemigrations", "createsuperuser",
    "collectstatic", "check", "startapp", "startproject", "dbshell",
    "dumpdata", "loaddata", "flush", "inspectdb", "showmigrations",
    "sqlmigrate", "sqlflush", "diffsettings", "showmigrations", "clearsessions",
  }

  -- Try to extract additional commands from the project
  local handle = io.popen("python " .. options.manage_py_path .. " help --commands 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()

    if result and result ~= "" then
      -- Parse the command output
      for cmd in string.gmatch(result, "%S+") do
        table.insert(django_commands, cmd)
      end
    end
  end

  -- Remove duplicates
  local seen = {}
  local unique_commands = {}
  for _, cmd in ipairs(django_commands) do
    if not seen[cmd] then
      table.insert(unique_commands, cmd)
      seen[cmd] = true
    end
  end

  return unique_commands
end

-- List Django management commands using Telescope
M.list_commands = function()
  local commands = get_django_commands()

  pickers.new({}, {
    prompt_title = "Django Commands",
    finder = finders.new_table({
      results = commands,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        -- Prompt for arguments
        vim.ui.input({ prompt = "Arguments: " }, function(args)
          local cmd = selection.value
          if args and args ~= "" then
            cmd = cmd .. " " .. args
          end
          M.run_command(cmd)
        end)
      end)
      return true
    end,
  }):find()
end

return M
