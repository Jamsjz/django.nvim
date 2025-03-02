-- lua/django/navigation.lua
-- Navigation functions for Django apps and files

local M = {}
local config = {}

-- Initialize navigation module
function M.setup(opts)
  config = opts
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function navigate_to_file(path)
  vim.cmd("edit " .. path)
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local function get_file_path(app_path, file_name)
  return app_path .. "/" .. file_name
end

local function find_django_apps()
  local utils = require("django.utils")
  return utils.find_django_apps(config.project_root)
end

local function telescope_available()
  local utils = require("django.utils")
  return config.telescope_enabled and utils.has_plugin("telescope")
end

local function build_app_entries(apps, file_name)
  local app_entries = {}
  for _, app in ipairs(apps) do
    local file_path = get_file_path(app.path, file_name)
    if file_exists(file_path) then
      table.insert(app_entries, {
        value = app,
        file_path = file_path,
        display = app.name,
        ordinal = app.name,
      })
    end
  end
  return app_entries
end

local function open_telescope_picker(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  pickers.new({}, {
    prompt_title = opts.prompt_title,
    finder = finders.new_table({
      results = opts.entries,
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
    attach_mappings = opts.attach_mappings,
  }):find()
end

local function open_ui_select(items, prompt, callback)
  vim.ui.select(items, {
    prompt = prompt,
  }, callback)
end

-- Find and navigate to a Django app
function M.find_app()
  -- Check if telescope is available
  if config.telescope_enabled and not require("django.utils").has_plugin("telescope") then
    notify("Telescope is required for app navigation but not available", vim.log.levels.ERROR)
    return
  end

  -- Find Django apps
  local apps = find_django_apps()

  if #apps == 0 then
    notify("No Django apps found in the project", vim.log.levels.WARN)
    return
  end

  -- If telescope is available, use it for finding apps
  if telescope_available() then
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local app_entries = {}
    for _, app in ipairs(apps) do
      table.insert(app_entries, {
        value = app,
        display = app.name,
        ordinal = app.name,
      })
    end

    local function attach_mappings(prompt_bufnr, map, app)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      local function navigate_to_app_file(file_name)
        local path = get_file_path(app.path, file_name)
        if file_exists(path) then
          actions.close(prompt_bufnr)
          navigate_to_file(path)
        else
          notify(file_name .. " not found for " .. app.name, vim.log.levels.WARN)
        end
      end

      -- Default action: views.py
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          local app = selection.value
          local views_path = get_file_path(app.path, "views.py")

          if file_exists(views_path) then
            actions.close(prompt_bufnr)
            navigate_to_file(views_path)
          else
            actions.close(prompt_bufnr)
            navigate_to_file(app.path) -- Navigate to app directory as fallback
          end
        end
      end)


      map("i", "<C-m>", function() navigate_to_app_file("models.py") end)
      map("i", "<C-u>", function() navigate_to_app_file("urls.py") end)
      map("i", "<C-a>", function() navigate_to_app_file("admin.py") end)
      map("i", "<C-t>", function() navigate_to_app_file("tests.py") end)
      map("i", "<C-f>", function() navigate_to_app_file("forms.py") end)

      return true
    end

    open_telescope_picker({
      prompt_title = "Django Apps",
      entries = app_entries,
      attach_mappings = function(prompt_bufnr, map)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          local app = selection.value
          return attach_mappings(prompt_bufnr, map, app)
        end
        return true
      end,
    })
  else
    -- Fallback if telescope is not available: simple menu
    local items = {}
    local app_map = {}

    for i, app in ipairs(apps) do
      items[i] = i .. ". " .. app.name
      app_map[i] = app
    end

    open_ui_select(items, "Select Django app:", function(choice)
      if not choice then return end

      local index = tonumber(choice:match("^(%d+)%."))
      if not index then return end

      local app = app_map[index]
      local views_path = get_file_path(app.path, "views.py")

      if file_exists(views_path) then
        navigate_to_file(views_path)
      else
        navigate_to_file(app.path)
      end
    end)
  end
end

-- Navigate to a specific Django file
function M.goto_django_file(file_type)
  local apps = find_django_apps()

  if #apps == 0 then
    notify("No Django apps found in the project", vim.log.levels.WARN)
    return
  end

  local file_extensions = {
    views = "views.py",
    models = "models.py",
    urls = "urls.py",
    admin = "admin.py",
    tests = "tests.py",
    forms = "forms.py",
  }

  local file_name = file_extensions[file_type]
  if not file_name then
    notify("Unknown file type: " .. file_type, vim.log.levels.ERROR)
    return
  end

  local function find_and_navigate(app)
    local file_path = get_file_path(app.path, file_name)
    if file_exists(file_path) then
      navigate_to_file(file_path)
      return true
    end
    return false
  end

  if telescope_available() then
    local telescope = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    local app_entries = {}
    for _, app in ipairs(apps) do
      local file_path = get_file_path(app.path, file_name)
      if file_exists(file_path) then
        table.insert(app_entries, {
          value = app,
          file_path = file_path,
          display = app.name,
          ordinal = app.name,
        })
      end
    end

    if #app_entries == 0 then
      notify("No " .. file_type .. " files found in any app", vim.log.levels.WARN)
      return
    end

    open_telescope_picker({
      prompt_title = "Django Apps - " .. file_type,
      entries = app_entries,
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection and selection.file_path then
            navigate_to_file(selection.file_path)
          end
        end)

        return true
      end,
    })
  else
    -- Fallback for non-telescope usage
    local items = {}
    local app_map = {}

    for i, app in ipairs(apps) do
      local file_path = get_file_path(app.path, file_name)
      if file_exists(file_path) then
        local item = i .. ". " .. app.name
        table.insert(items, item)
        app_map[item] = file_path
      end
    end

    if #items == 0 then
      notify("No " .. file_type .. " files found in any app", vim.log.levels.WARN)
      return
    end

    vim.ui.select(items, {
      prompt = "Select app for " .. file_type .. ":",
    }, function(choice)
      if not choice then return end

      local file_path = app_map[choice]
      if file_path then
        navigate_to_file(file_path)
      end
    end)
  end
end

return M
