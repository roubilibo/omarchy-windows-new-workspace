-- Hyprland event handler and optional Super+Alt+L toggle for the plugin.

if rawget(_G, "__windows_new_workspace_plugin") then
  return true
end

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
  return false
end

_G.__windows_new_workspace_plugin = true

local home = os.getenv("HOME") or ""
local state_home = os.getenv("XDG_STATE_HOME")
if not state_home or state_home == "" then
  state_home = home .. "/.local/state"
end
local state_dir = state_home .. "/omarchy"
local state_path = state_dir .. "/windows-new-workspace"

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

os.execute("mkdir -p " .. shell_quote(state_dir))

local function save_enabled(value)
  local file = io.open(state_path, "w")
  if not file then return end
  file:write(value and "true\n" or "false\n")
  file:close()
end

local function load_enabled()
  local file = io.open(state_path, "r")
  if not file then return true end
  local value = file:read("*a") or ""
  file:close()
  if value:match("^%s*false%s*$") then return false end
  return true
end

_G.__windows_new_workspace_enabled = load_enabled()
save_enabled(_G.__windows_new_workspace_enabled)

local function toggle_enabled()
  _G.__windows_new_workspace_enabled = not _G.__windows_new_workspace_enabled
  save_enabled(_G.__windows_new_workspace_enabled)
  hl.exec_cmd(o.notify("New tiled windows on new workspace: "
    .. (_G.__windows_new_workspace_enabled and "ON" or "OFF")))
end

_G.__windows_new_workspace_toggle = toggle_enabled

hl.unbind("SUPER + ALT + L")
o.bind("SUPER + ALT + L", "Toggle new tiled windows on new workspace", toggle_enabled)

local function has_existing_tiled_window(workspace, new_window)
  for _, existing in ipairs(hl.get_workspace_windows(workspace.id)) do
    if existing.address ~= new_window.address
      and not existing.floating
      and not existing.pinned
    then
      return true
    end
  end
  return false
end

-- `window.open` fires after static window rules have set floating and pin state.
hl.on("window.open", function(window)
  if not _G.__windows_new_workspace_enabled
    or not window
    or window.floating
    or window.pinned
    or not window.workspace
  then
    return
  end

  local source_workspace = window.workspace
  local source_name = source_workspace.name or ""
  if (source_workspace.id and source_workspace.id < 1)
    or source_name:match("^special:")
  then
    return
  end

  if not has_existing_tiled_window(source_workspace, window) then
    return
  end

  local highest_workspace_id = 0
  for _, workspace in ipairs(hl.get_workspaces()) do
    local name = workspace.name or ""
    if workspace.id and workspace.id > highest_workspace_id
      and not name:match("^special:")
    then
      highest_workspace_id = workspace.id
    end
  end

  hl.dispatch(hl.dsp.window.move({
    window = window,
    workspace = highest_workspace_id + 1,
    follow = true,
  }))
end)

return true
