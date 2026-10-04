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

local function save_state()
  local file = io.open(state_path, "w")
  if not file then return end
  file:write(_G.__windows_new_workspace_enabled and "true\n" or "false\n")
  file:write(_G.__windows_new_workspace_keep_terminal and "true\n" or "false\n")
  file:close()
end

local function load_state()
  local file = io.open(state_path, "r")
  if not file then return true, false end
  local enabled_value = file:read("*l") or ""
  local keep_terminal_value = file:read("*l") or ""
  file:close()
  return enabled_value:match("^%s*false%s*$") == nil,
    keep_terminal_value:match("^%s*true%s*$") ~= nil
end

_G.__windows_new_workspace_enabled, _G.__windows_new_workspace_keep_terminal = load_state()
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

local function move_to_new_workspace_if_needed(window)
  if not _G.__windows_new_workspace_enabled
    or not window
    or window.floating
    or window.pinned
    or not window.workspace
  then
    return
  end

  if _G.__windows_new_workspace_keep_terminal then
    for _, tag in ipairs(window.tags or {}) do
      if tag:gsub("%*$", "") == "terminal" then
        return
      end
    end
  end

  local source_workspace = window.workspace
  local source_name = source_workspace.name or ""
  if (source_workspace.id and source_workspace.id < 1)
    or source_name:match("^special:")
  then
    return
  end

  local has_existing_tiled_window = false
  for _, existing in ipairs(hl.get_workspace_windows(source_workspace.id)) do
    if existing.address ~= window.address
      and not existing.floating
      and not existing.pinned
    then
      has_existing_tiled_window = true
      break
    end
  end
  if not has_existing_tiled_window then
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
end

-- Move every newly opened tiled window immediately. App-specific title
-- handling belongs in the user's Hyprland configuration, not this plugin.
hl.on("window.open", function(window)
  move_to_new_workspace_if_needed(window)
end)

-- `window.destroy` runs after a window's weak reference has expired, so its
-- properties (including address) are nil. Pair destroy events with close
-- events in order; keep false entries for closes that should not move workspaces.
local closing_windows = {}
local closing_windows_head = 1
local closing_windows_tail = 0
hl.on("window.close", function(window)
  local workspace_id = false
  if _G.__windows_new_workspace_enabled
    and window
    and not window.floating
    and not window.pinned
    and window.workspace
  then
    local workspace = window.workspace
    local name = workspace.name or ""
    if workspace.id and workspace.id >= 1 and not name:match("^special:") then
      workspace_id = workspace.id
    end
  end

  closing_windows_tail = closing_windows_tail + 1
  closing_windows[closing_windows_tail] = workspace_id
end)

hl.on("window.destroy", function()
  if closing_windows_head > closing_windows_tail then
    return
  end

  local closed_workspace_id = closing_windows[closing_windows_head]
  closing_windows[closing_windows_head] = nil
  closing_windows_head = closing_windows_head + 1
  if closing_windows_head > closing_windows_tail then
    closing_windows = {}
    closing_windows_head = 1
    closing_windows_tail = 0
  end

  if not _G.__windows_new_workspace_enabled or not closed_workspace_id then
    return
  end

  local active_workspace = hl.get_active_workspace()
  if not active_workspace or active_workspace.id ~= closed_workspace_id then
    return
  end

  local closed_workspace = hl.get_workspace(closed_workspace_id)
  if closed_workspace and closed_workspace.windows > 0 then
    return
  end

  local nearest_workspace_id = nil
  local nearest_distance = nil
  for _, workspace in ipairs(hl.get_workspaces()) do
    local name = workspace.name or ""
    if workspace.id and workspace.id >= 1 and not name:match("^special:")
      and workspace.windows > 0
    then
      local distance = math.abs(workspace.id - closed_workspace_id)
      if not nearest_distance or distance < nearest_distance
        or (distance == nearest_distance and workspace.id < nearest_workspace_id)
      then
        nearest_workspace_id = workspace.id
        nearest_distance = distance
      end
    end
  end

  if nearest_workspace_id then
    hl.dispatch(hl.dsp.focus({ workspace = tostring(nearest_workspace_id) }))
  end
end)

return true
