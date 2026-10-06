-- Hyprland plugin entry point. Keeps lifecycle checks and module loading here.

local function enabled()
  local path = (os.getenv("HOME") or "") .. "/.config/omarchy/shell.json"
  local file = io.open(path, "r")
  if not file then
    return false
  end

  local config = file:read("a") or ""
  file:close()
  return config:find('"roubilibo.windows-new-workspace"', 1, true) ~= nil
end

if not enabled() then
  _G.__windows_new_workspace_enabled = false
  return false
end

_G.__windows_new_workspace_plugin = true

local source = debug.getinfo(1, "S").source
local plugin_dir = source:sub(2):match("(.*/)") or ""
dofile(plugin_dir .. "plugin-logic.lua")
dofile(plugin_dir .. "window-behavior.lua")

return true
