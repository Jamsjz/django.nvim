-- lua/django/navigation.lua
-- Navigation functions for Django apps and files

local M = {}
local config = {}

-- Initialize navigation module with configuration options
function M.setup(opts)
  config = opts or {}

  -- Set default keymaps if not provided
  config.keymaps = config.keymaps or {}
  config.keymaps.views = config.keymaps.views or "<C-v>"
  config.keymaps.models = config.keymaps.models or "<C-m>"
  config.keymaps.urls = config.keymaps.urls or "<C-u>"
  config.keymaps.admin = config.keymaps.admin or "<C-a>"
  config.keymaps.tests = config.keymaps.tests or "<C-t>"
  config.keymaps.forms = config.keymaps.forms or "<C-f>"
  config.keymaps.migrations = config.keymaps.migrations or "<C-d>"
end

-- Helper function to open a file or notify if not found
local function open_file_or_notify(file_path, file_type, app_name)
  if vim.fn.filereadable(file_path) == 1 then
    vim.cmd("edit " .. file_path)
  else
    vim.notify(file_type .. " not found for " .. app_name, vim.log.levels.WARN)
  end
end

-- Helper function to navigate to a specific file in a Django app
local function navigate_to_file(app, file_type)
  if not app then return end

  local file_paths = {
    views = app.path .. "/views.py",
    models = app.path .. "/models.py",
    urls = app.path .. "/urls.py",
    admin = app.path .. "/admin.py",
    tests = app.path .. "/tests.py",
    forms = app.path .. "/forms.py",
    migrations = app.path .. "/migrations"
  }

  local file_path = file_paths[file_type]

  -- Special case for migrations directory
  if file_type == "migrations" then
    if vim.fn.isdirectory(file_path) == 1 then
      -- Navigate to the migrations directory using netrw
      vim.cmd("edit " .. file_path)
    else
      vim.notify("Migrations directory not found for " .. app.name, vim.log.levels.WARN)
    end
  else
    open_file_or_notify(file_path, file_type, app.name)
  end
end

-- Find and navigate to a Django app
function M.find_app()
  local utils = require("django.utils")

  -- Check if telescope is available
  if config.telescope_enabled and not utils.has_plugin("telescope") then
    vim.notify("Telescope is required for app navigation but not available", vim.log.levels.ERROR)
    return
  end

  -- Find Django apps
  local apps = utils.find_django_apps(config.project_root)

  if #apps == 0 then
    vim.notify("No Django apps found in the project", vim.log.levels.WARN)
    return
  end

  -- If telescope is available, use it for finding apps
  if config.telescope_enabled then
    local telescope = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    local app_entries = {}
    for _, app in ipairs(apps) do
      table.insert(app_entries, {
        value = app,
        display = app.name,
        ordinal = app.name,
      })
    end

    pickers.new({}, {
      prompt_title = "Django Apps",
      finder = finders.new_table({
        results = app_entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.ordinal,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- Navigate to views.py when the app is selected (default)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "views")
          end
        end)

        -- Custom mappings for different app files
        -- Views mapping (explicitly adding for clarity)
        map("i", config.keymaps.views, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "views")
          end
        end)

        -- Models mapping
        map("i", config.keymaps.models, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "models")
          end
        end)

        -- URLs mapping
        map("i", config.keymaps.urls, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "urls")
          end
        end)

        -- Admin mapping
        map("i", config.keymaps.admin, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "admin")
          end
        end)

        -- Tests mapping
        map("i", config.keymaps.tests, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "tests")
          end
        end)

        -- Forms mapping
        map("i", config.keymaps.forms, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "forms")
          end
        end)

        -- NEW: Migrations mapping
        map("i", config.keymaps.migrations, function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.value then
            navigate_to_file(selection.value, "migrations")
          end
        end)

        return true
      end,
    }):find()
  else
    -- Fallback if telescope is not available: simple menu
    local items = {}
    for i, app in ipairs(apps) do
      table.insert(items, i .. ". " .. app.name)
    end

    vim.ui.select(items, {
      prompt = "Select Django app:",
    }, function(choice)
      if not choice then return end

      -- Extract index from choice
      local index = tonumber(choice:match("^(%d+)%."))
      if not index then return end

      local app = apps[index]
      -- Default to opening views.py
      navigate_to_file(app, "views")
    end)
  end
end

-- Navigate to a specific Django file
function M.goto_django_file(file_type)
  local utils = require("django.utils")
  local apps = utils.find_django_apps(config.project_root)

  if #apps == 0 then
    vim.notify("No Django apps found in the project", vim.log.levels.WARN)
    return
  end

  local valid_file_types = {
    views = true,
    models = true,
    urls = true,
    admin = true,
    tests = true,
    forms = true,
    migrations = true
  }

  if not valid_file_types[file_type] then
    vim.notify("Unknown file type: " .. file_type, vim.log.levels.ERROR)
    return
  end

  -- Use the same navigation logic as find_app but with specific file type
  if config.telescope_enabled and utils.has_plugin("telescope") then
    local telescope = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    local app_entries = {}
    for _, app in ipairs(apps) do
      -- For migrations, check if directory exists
      if file_type == "migrations" then
        local dir_path = app.path .. "/migrations"
        if vim.fn.isdirectory(dir_path) == 1 then
          table.insert(app_entries, {
            value = app,
            file_path = dir_path,
            display = app.name,
            ordinal = app.name,
          })
        end
      else
        local file_path = app.path .. "/" .. file_type .. ".py"
        if vim.fn.filereadable(file_path) == 1 then
          table.insert(app_entries, {
            value = app,
            file_path = file_path,
            display = app.name,
            ordinal = app.name,
          })
        end
      end
    end

    if #app_entries == 0 then
      vim.notify("No " .. file_type .. " found in any app", vim.log.levels.WARN)
      return
    end

    pickers.new({}, {
      prompt_title = "Django Apps - " .. file_type,
      finder = finders.new_table({
        results = app_entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            file_path = entry.file_path,
            display = entry.display,
            ordinal = entry.ordinal,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.file_path then
            vim.cmd("edit " .. selection.file_path)
          end
        end)

        return true
      end,
    }):find()
  else
    -- Fallback for non-telescope usage
    local items = {}
    local app_map = {}

    for i, app in ipairs(apps) do
      local file_path
      if file_type == "migrations" then
        file_path = app.path .. "/migrations"
        if vim.fn.isdirectory(file_path) == 1 then
          local item = i .. ". " .. app.name
          table.insert(items, item)
          app_map[item] = file_path
        end
      else
        file_path = app.path .. "/" .. file_type .. ".py"
        if vim.fn.filereadable(file_path) == 1 then
          local item = i .. ". " .. app.name
          table.insert(items, item)
          app_map[item] = file_path
        end
      end
    end

    if #items == 0 then
      vim.notify("No " .. file_type .. " found in any app", vim.log.levels.WARN)
      return
    end

    vim.ui.select(items, {
      prompt = "Select app for " .. file_type .. ":",
    }, function(choice)
      if not choice then return end

      local file_path = app_map[choice]
      if file_path then
        vim.cmd("edit " .. file_path)
      end
    end)
  end
end

return M
