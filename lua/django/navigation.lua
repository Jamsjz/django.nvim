-- django.nvim - Navigation module
-- Handles navigation for URLs, models, templates, etc.

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local M = {}
local options = {}

-- Setup function
M.setup = function(opts)
  options = opts
end

-- Find Django URL patterns
M.find_routes = function()
  -- Use ripgrep to find urlpatterns
  local command = "rg --vimgrep 'urlpatterns\\s*=|path\\([^)]*\\)' -g '*.py'"

  local handle = io.popen(command)
  if not handle then
    vim.notify("Error: Could not run ripgrep. Is it installed?", vim.log.levels.ERROR)
    return
  end

  local results = {}
  for line in handle:lines() do
    table.insert(results, line)
  end
  handle:close()

  if #results == 0 then
    vim.notify("No URL patterns found.", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Django URL Patterns",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local file, line, _, text = entry:match("([^:]+):(%d+):(%d+):(.*)")
        return {
          value = entry,
          display = file .. ":" .. line .. " - " .. text:gsub("^%s*", ""),
          ordinal = file .. " " .. text,
          filename = file,
          lnum = tonumber(line),
          text = text,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.grep_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. selection.filename)
        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
        vim.cmd("normal! zz")
      end)
      return true
    end,
  }):find()
end

-- Find Django models
M.find_models = function()
  local command = "rg --vimgrep 'class\\s+[A-Za-z0-9_]+\\(\\s*(models\\.Model|Model)' -g '*.py'"

  local handle = io.popen(command)
  if not handle then
    vim.notify("Error: Could not run ripgrep. Is it installed?", vim.log.levels.ERROR)
    return
  end

  local results = {}
  for line in handle:lines() do
    table.insert(results, line)
  end
  handle:close()

  if #results == 0 then
    vim.notify("No models found.", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Django Models",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local file, line, _, text = entry:match("([^:]+):(%d+):(%d+):(.*)")
        local model_name = text:match("class%s+([A-Za-z0-9_]+)")
        return {
          value = entry,
          display = model_name .. " - " .. file,
          ordinal = model_name .. " " .. file,
          filename = file,
          lnum = tonumber(line),
          text = text,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.grep_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. selection.filename)
        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
        vim.cmd("normal! zz")
      end)
      return true
    end,
  }):find()
end

-- Find Django templates
M.find_templates = function()
  local templates_path = options.templates_path
  if templates_path:sub(-1) ~= "/" then
    templates_path = templates_path .. "/"
  end

  local command = "find " .. templates_path .. " -type f -name '*.html' 2>/dev/null"

  local handle = io.popen(command)
  if not handle then
    vim.notify("Error: Could not find templates. Check your templates path.", vim.log.levels.ERROR)
    return
  end

  local results = {}
  for line in handle:lines() do
    table.insert(results, line)
  end
  handle:close()

  if #results == 0 then
    vim.notify("No templates found in " .. templates_path, vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Django Templates",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local display = entry:gsub(templates_path, "")
        return {
          value = entry,
          display = display,
          ordinal = display,
          filename = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. selection.filename)
      end)
      return true
    end,
  }):find()
end

-- List Django apps
M.list_apps = function()
  local command = "find . -maxdepth 2 -type f -name 'apps.py' 2>/dev/null | sed 's/\\/apps\\.py//' | sed 's/\\.\\///'"

  local handle = io.popen(command)
  if not handle then
    vim.notify("Error: Could not find Django apps.", vim.log.levels.ERROR)
    return
  end

  local results = {}
  for line in handle:lines() do
    table.insert(results, line)
  end
  handle:close()

  if #results == 0 then
    vim.notify("No Django apps found.", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Django Apps",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
          path = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        -- Open app directory in file browser
        local has_nvim_tree = pcall(require, "nvim-tree")
        if has_nvim_tree then
          require("nvim-tree.api").tree.open({ path = selection.path })
        else
          vim.cmd("edit " .. selection.path)
        end
      end)
      return true
    end,
  }):find()
end

return M
