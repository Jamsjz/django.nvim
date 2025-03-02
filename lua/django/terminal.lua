local M = {}
local options = {}

-- Setup function
M.setup = function(opts)
  options = opts
end

-- Toggle terminal window
M.toggle_term = function()
  local has_toggleterm, toggleterm = pcall(require, "toggleterm")
  if has_toggleterm then
    toggleterm.toggle(1)
  else
    -- Fallback if toggleterm is not available
    if options.terminal.position == "horizontal" then
      vim.cmd("botright new | resize " .. options.terminal.size .. " | terminal")
    elseif options.terminal.position == "vertical" then
      vim.cmd("vnew | vertical resize " .. options.terminal.size .. " | terminal")
    else -- float
      vim.cmd("new | wincmd J | resize " .. options.terminal.size .. " | terminal")
    end
    vim.cmd("startinsert")
  end
end

-- Virtual environment activation
M.activate_venv = function()
  if not options.virtual_env_path then
    vim.notify("Virtual environment path not set", vim.log.levels.WARN)
    return
  end

  local venv_path = vim.fn.expand(options.virtual_env_path)

  -- Check if venv-selector.nvim is available
  local has_venv, venv = pcall(require, "venv-selector")
  if has_venv then
    venv.activate(venv_path)
    vim.notify("Activated virtual environment: " .. venv_path, vim.log.levels.INFO)
    return
  end

  -- Fallback if venv-selector.nvim is not available
  local activate_script = venv_path .. "/bin/activate"
  if vim.fn.has("win32") == 1 then
    activate_script = venv_path .. "\\Scripts\\activate.bat"
  end

  if vim.fn.filereadable(activate_script) == 1 then
    local has_toggleterm, toggleterm = pcall(require, "toggleterm")
    if has_toggleterm then
      toggleterm.exec("source " .. activate_script)
      vim.notify("Activated virtual environment: " .. venv_path, vim.log.levels.INFO)
    else
      vim.notify("To activate venv manually: source " .. activate_script, vim.log.levels.INFO)
    end
  else
    vim.notify("Virtual environment activation script not found", vim.log.levels.ERROR)
  end
end

return M
