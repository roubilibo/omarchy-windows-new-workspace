# New Workspace for Tiled Windows

Hyprland plugin that moves each newly opened tiled, unpinned window to a fresh
workspace. Floating and pinned windows stay where they open. Windows opened on
special workspaces, including the scratchpad, are ignored.

When automatic placement is enabled and the last tiled window on the active
regular workspace is closed, the plugin moves to the numerically nearest
regular workspace that still has a window. Manually switching to an empty
workspace does not trigger this behavior.

`Super+L` keeps cycling the active workspace layout. `Super+Alt+L` toggles
automatic placement and sends an Omarchy notification with the new state.
Right-clicking the bar icon also toggles automatic placement. Left-clicking it
opens an options menu with a persistent `Keep terminal` setting. When both
automatic placement and `Keep terminal` are enabled, newly opened terminal
windows stay on their opening workspace while other tiled windows move to a
new workspace. Terminal detection uses Omarchy's `terminal` window tag. The
bar icon stays visible and its active and inactive shapes differ; the inactive
icon does not use opacity or muted colors.

## Install

Run this from an interactive terminal to install and enable the plugin with
Omarchy's plugin manager:

```bash
omarchy plugin add https://github.com/roubilibo/omarchy-windows-new-workspace.git --enable
```

Omarchy validates the manifest, then asks where to place the bar icon: left,
center, or right. Right is preselected. Do not add `--yes`; that skips the
interactive placement choice. You can change the section later with
`omarchy bar move roubilibo.windows-new-workspace --section <left|center|right>`.

## Install Hyprland binding

Add this loader block to `~/.config/hypr/bindings.lua`:

```lua
-- BEGIN roubilibo.windows-new-workspace managed keybindings
do
  local plugin = os.getenv("HOME") .. "/.config/omarchy/plugins/roubilibo.windows-new-workspace/hypr/windows-new-workspace.lua"
  local file = io.open(plugin, "r")
  if file then
    file:close()
    pcall(dofile, plugin)
  end
end
-- END roubilibo.windows-new-workspace managed keybindings
```

The loader is needed because shell plugin installation does not load Hyprland
Lua files automatically. Reload Hyprland after adding the block or changing the
plugin's Hyprland Lua file:

```bash
hyprctl reload
```

## Dependencies

Requires Omarchy's Quickshell plugin system, Hyprland with Omarchy's Lua
helpers, and `hyprctl`. It uses no external packages or network services.

## Remove

Remove the managed loader block from `~/.config/hypr/bindings.lua`, then reload
Hyprland and remove the shell plugin:

```bash
hyprctl reload
omarchy plugin remove roubilibo.windows-new-workspace
```

The saved settings are in `$XDG_STATE_HOME/omarchy/windows-new-workspace`, or
`~/.local/state/omarchy/windows-new-workspace` when `XDG_STATE_HOME` is unset.
Delete that file separately if you also want to remove the saved state.

## Layout

- `manifest.json` and `src/Service.qml` let Omarchy discover and enable this
  headless Hyprland plugin; the manifest also registers the status bar icon.
- `hypr/windows-new-workspace.lua` owns the keybinding and window-open rule.
- `src/StatusWidget.qml` shows the saved toggle state in the bar.
- `README.md` documents installation and behavior.

## License

MIT
