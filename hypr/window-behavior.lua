-- Workspace behavior for opened and closed windows.

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

  local keep_matches = _G.__windows_new_workspace_keep_tags or {}
  for _, keep_match in ipairs(keep_matches) do
    if window.class == keep_match then
      return
    end
  end
  for _, tag in ipairs(window.tags or {}) do
    local normalized_tag = tag:gsub("%*$", "")
    for _, keep_match in ipairs(keep_matches) do
      if normalized_tag == keep_match then
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

-- Keep event registrations stable across Hyprland config reloads. The global
-- handlers are replaced by each dofile, while these wrappers always call the
-- latest implementation without registering duplicate callbacks.
_G.__windows_new_workspace_on_open = move_to_new_workspace_if_needed
_G.__windows_new_workspace_on_close = move_to_nearest_workspace_after_close

if not _G.__windows_new_workspace_handlers_registered then
  hl.on("window.open", function(window)
    local handler = _G.__windows_new_workspace_on_open
    if handler then handler(window) end
  end)

  hl.on("window.close", function(window)
    local handler = _G.__windows_new_workspace_on_close
    if handler then handler(window) end
  end)

  _G.__windows_new_workspace_handlers_registered = true
end
