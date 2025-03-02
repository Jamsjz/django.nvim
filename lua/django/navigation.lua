-- lua/django/navigation.lua
-- Navigation functions for Django apps and files

local M = {}
local config = {}

-- Initialize navigation module
function M.setup(opts)
  config = opts
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
        -- Navigate to views.py when the app is selected
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          
          if selection and selection.value then
            local app = selection.value
            local views_path = app.path .. "/views.py"
            
            -- Check if views.py exists, otherwise try to navigate to the app directory
            if vim.fn.filereadable(views_path) == 1 then
              vim.cmd("edit " .. views_path)
            else
              vim.cmd("edit " .. app.path)
            end
          end
        end)
        
        -- Custom mappings for different app files
        map("i", "<C-m>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          
          if selection and selection.value then
            local app = selection.value
            local models_path = app.path .. "/models.py"
            
            if vim.fn.filereadable(models_path) == 1 then
              vim.cmd("edit " .. models_path)
            else
              vim.notify("models.py not found for " .. app.name, vim.log.levels.WARN)
            end
          end
        end)
        
        map("i", "<C-u>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          
          if selection and selection.value then
            local app = selection.value
            local urls_path = app.path .. "/urls.py"
            
            if vim.fn.filereadable(urls_path) == 1 then
              vim.cmd("edit " .. urls_path)
            else
              vim.notify("urls.py not found for " .. app.name, vim.log.levels.WARN)
            end
          end
        end)
        
        map("i", "<C-a>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          
          if selection and selection.value then
            local app = selection.value
            local admin_path = app.path .. "/admin.py"
            
            if vim.fn.filereadable(admin_path) == 1 then
              vim.cmd("edit " .. admin_path)
            else
              vim.notify("admin.py not found for " .. app.name, vim.log.levels.WARN)
            end
          end
        end)
        
        map("i", "<C-t>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          
          if selection and selection.value then
            local app = selection.value
            local tests_path = app.path .. "/tests.py"
            
            if vim.fn.filereadable(tests_path) == 1 then
              vim.cmd("edit " .. tests_path)
            else
              vim.notify("tests.py not found for " .. app.name, vim.log.levels.WARN)
            end
          end
        end)
        
        map("i", "<C-f>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          
          if selection and selection.value then
            local app = selection.value
            local forms_path = app.path .. "/forms.py"
            
            if vim.fn.filereadable(forms_path) == 1 then
              vim.cmd("edit " .. forms_path)
            else
              vim.notify("forms.py not found for " .. app.name, vim.log.levels.WARN)
            end
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
      local views_path = app.path .. "/views.py"
      
      if vim.fn.filereadable(views_path) == 1 then
        vim.cmd("edit " .. views_path)
      else
        vim.cmd("edit " .. app.path)
      end
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
  
  local file_extensions = {
    views = "/views.py",
    models = "/models.py",
    urls = "/urls.py",
    admin = "/admin.py",
    tests = "/tests.py",
    forms = "/forms.py",
  }
  
  local file_ext = file_extensions[file_type]
  if not file_ext then
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
      local file_path = app.path .. file_ext
      if vim.fn.filereadable(file_path) == 1 then
        table.insert(app_entries, {
          value = app,
          file_path = file_path,
          display = app.name,
          ordinal = app.name,
        })
      end
    end
    
    if #app_entries == 0 then
      vim.notify("No " .. file_type .. " files found in any app", vim.log.levels.WARN)
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
      local file_path = app.path .. file_ext
      if vim.fn.filereadable(file_path) == 1 then
        local item = i .. ". " .. app.name
        table.insert(items, item)
        app_map[item] = file_path
      end
    end
    
    if #items == 0 then
      vim.notify("No " .. file_type .. " files found in any app", vim.log.levels.WARN)
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
