# New Workspace for Tiled Windows

Hyprland plugin that moves each newly opened tiled, unpinned window to a fresh
workspace. Floating and pinned windows stay where they open. Windows opened on
special workspaces, including the scratchpad, are ignored.

`Super+L` keeps cycling the active workspace layout. `Super+Alt+L` toggles
automatic placement and sends an Omarchy notification with the new state. The
bar icon stays visible and toggles the feature when clicked. Its active and
inactive shapes differ; the inactive icon does not use opacity or muted colors.

## Install

For a published Git repository, use Omarchy's plugin installer:

```bash
omarchy plugin add <git-url> --enable
```

For local development from this repository, validate the plugin, copy it to
Omarchy's user plugin directory, then register and enable it:

```bash
omarchy plugin validate ./roubilibo.windows-new-workspace
mkdir -p ~/.config/omarchy/plugins/roubilibo.windows-new-workspace
cp -a ./roubilibo.windows-new-workspace/. ~/.config/omarchy/plugins/roubilibo.windows-new-workspace/
omarchy-shell shell rescanPlugins
omarchy plugin enable roubilibo.windows-new-workspace --section right
```

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

The `--section right` option places its status icon in the right bar section;
choose another section if desired. The loader only registers the feature while
the plugin ID is enabled in `~/.config/omarchy/shell.json`. Disabling the plugin
and reloading Hyprland removes the binding and window event handler. Remove the
block to remove the loader entirely. The toggle state is saved under
`~/.local/state/omarchy/windows-new-workspace`.

## Layout

- `manifest.json` and `src/Service.qml` let Omarchy discover and enable this
  headless Hyprland plugin; the manifest also registers the status bar icon.
- `hypr/windows-new-workspace.lua` owns the keybinding and window-open rule.
- `src/StatusWidget.qml` shows the saved toggle state in the bar.
- `README.md` documents installation and behavior.

## License

MIT
