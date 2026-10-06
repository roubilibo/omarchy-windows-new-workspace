-- Persistent settings, notifications, and keybinding.

local home = os.getenv("HOME") or ""
local state_home = os.getenv("XDG_STATE_HOME")
if not state_home or state_home == "" then
  state_home = home .. "/.local/state"
end
local state_dir = state_home .. "/omarchy"
local state_path = state_dir .. "/windows-new-workspace"
local source = debug.getinfo(1, "S").source
local plugin_dir = source:sub(2):match("(.*/)hypr/") or ""
local keep_classes_path = plugin_dir .. "window-exclusions.conf"

local function valid_tag(tag)
  return type(tag) == "string" and tag:match("^[%w_.%-]+$") ~= nil
end

local function load_keep_classes()
  local classes = {}
  local seen = {}
  local file = io.open(keep_classes_path, "r")
  if not file then return classes end

  for line in file:lines() do
    local value = line:match("^%s*(.-)%s*$")
    if value ~= "" and not value:match("^#") and valid_tag(value) and not seen[value] then
      classes[#classes + 1] = value
      seen[value] = true
    end
  end
  file:close()
  return classes
end

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

os.execute("mkdir -p " .. shell_quote(state_dir))

local function save_state()
  local temporary_path = state_path .. ".tmp"
  local file = io.open(temporary_path, "w")
  if not file then return end

  local write_ok = file:write(_G.__windows_new_workspace_enabled and "true\n" or "false\n")
  if write_ok then
    write_ok = file:write(_G.__windows_new_workspace_keep_terminal and "true\n" or "false\n")
  end
  local close_ok = file:close()
  if not write_ok or not close_ok then
    os.remove(temporary_path)
    return
  end

  local rename_ok = os.rename(temporary_path, state_path)
  if not rename_ok then
    os.remove(temporary_path)
  end
end

local function load_state()
  local file = io.open(state_path, "r")
  if not file then return true, false, {} end
  local enabled_value = file:read("*l") or ""
  local keep_terminal_value = file:read("*l") or ""
  file:close()
  return enabled_value:match("^%s*false%s*$") == nil,
    keep_terminal_value:match("^%s*true%s*$") ~= nil
end

_G.__windows_new_workspace_enabled, _G.__windows_new_workspace_keep_terminal = load_state()
_G.__windows_new_workspace_keep_tags = load_keep_classes()
save_state()

local function toggle_enabled()
  _G.__windows_new_workspace_enabled = not _G.__windows_new_workspace_enabled
  save_state()
  hl.exec_cmd(o.notify("New tiled windows on new workspace: "
    .. (_G.__windows_new_workspace_enabled and "ON" or "OFF")))
end

local function toggle_keep_terminal()
  _G.__windows_new_workspace_keep_terminal = not _G.__windows_new_workspace_keep_terminal
  save_state()
  hl.exec_cmd(o.notify("Keep terminal on its opening workspace: "
    .. (_G.__windows_new_workspace_keep_terminal and "ON" or "OFF")))
end

_G.__windows_new_workspace_toggle = toggle_enabled
_G.__windows_new_workspace_toggle_keep_terminal = toggle_keep_terminal

hl.unbind("SUPER + ALT + L")
o.bind("SUPER + ALT + L", "Toggle new tiled windows on new workspace", toggle_enabled)
