-- Workspace behavior for opened and closed windows.

local function matches_exclusion(window)
  local exclusions = _G.__windows_new_workspace_exclusions or {}
  local class_match = exclusions.class and exclusions.class[window.class]
  local title_match = exclusions.title and exclusions.title[window.title]
  local tag_match = false
  for _, tag in ipairs(window.tags or {}) do
    local normalized_tag = tag:gsub("%*$", "")
    if exclusions.tag and exclusions.tag[normalized_tag] then
      tag_match = true
      break
    end
  end

  local stable_match = class_match or tag_match
  return stable_match or title_match, title_match and not stable_match
end

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

  local excluded, title_only = matches_exclusion(window)
  if excluded then
    if title_only then
      local pending = _G.__windows_new_workspace_pending_title_exclusions or {}
      pending[window.address] = window.title
      _G.__windows_new_workspace_pending_title_exclusions = pending
    end
    return
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

local function move_to_nearest_workspace_after_close(window)
  if not _G.__windows_new_workspace_enabled
    or not window
    or window.floating
    or window.pinned
    or not window.workspace
  then
    return
  end

  local closed_workspace = window.workspace
  local closed_workspace_id = closed_workspace.id
  local closed_workspace_name = closed_workspace.name or ""
  if not closed_workspace_id or closed_workspace_id < 1
    or closed_workspace_name:match("^special:")
  then
    return
  end

  local active_workspace = hl.get_active_workspace()
  if not active_workspace or active_workspace.id ~= closed_workspace_id then
    return
  end

  local function has_tiled_window(workspace_id)
    for _, existing in ipairs(hl.get_workspace_windows(workspace_id)) do
      if existing.address ~= window.address
        and not existing.floating
        and not existing.pinned
      then
        return true
      end
    end
    return false
  end

  if has_tiled_window(closed_workspace_id) then
    return
  end

  local nearest_workspace_id = nil
  local nearest_distance = nil
  for _, workspace in ipairs(hl.get_workspaces()) do
    local name = workspace.name or ""
    if workspace.id and workspace.id >= 1 and not name:match("^special:")
      and workspace.id ~= closed_workspace_id
      and #hl.get_workspace_windows(workspace.id) > 0
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
end

local function handle_window_title(window)
  if not window or not window.address then
    return
  end

  local pending = _G.__windows_new_workspace_pending_title_exclusions
  local previous_title = pending and pending[window.address]
  if previous_title == nil or previous_title == window.title then
    return
  end

  local excluded, title_only = matches_exclusion(window)
  if excluded then
    if title_only then
      pending[window.address] = window.title
    else
      pending[window.address] = nil
    end
    return
  end

  pending[window.address] = nil
  -- Re-run the opening behavior after an initially matching title changes.
  local handler = _G.__windows_new_workspace_on_open
  if handler then handler(window) end
end

local function clear_pending_title_exclusion(window)
  local pending = _G.__windows_new_workspace_pending_title_exclusions
  if pending and window then
    pending[window.address] = nil
  end
end

-- Keep event registrations stable across Hyprland config reloads. The global
-- handlers are replaced by each dofile, while these wrappers always call the
-- latest implementation without registering duplicate callbacks.
_G.__windows_new_workspace_on_open = move_to_new_workspace_if_needed
_G.__windows_new_workspace_on_close = move_to_nearest_workspace_after_close
_G.__windows_new_workspace_on_title = handle_window_title
_G.__windows_new_workspace_clear_pending_title_exclusion = clear_pending_title_exclusion

if not _G.__windows_new_workspace_handlers_registered then
  hl.on("window.open", function(window)
    local handler = _G.__windows_new_workspace_on_open
    if handler then handler(window) end
  end)

  hl.on("window.close", function(window)
    local clear_handler = _G.__windows_new_workspace_clear_pending_title_exclusion
    if clear_handler then clear_handler(window) end

    local handler = _G.__windows_new_workspace_on_close
    if handler then handler(window) end
  end)

  hl.on("window.title", function(window)
    local handler = _G.__windows_new_workspace_on_title
    if handler then handler(window) end
  end)

  _G.__windows_new_workspace_handlers_registered = true
end
