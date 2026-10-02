import QtQuick

// Omarchy uses this headless service entry point to track plugin enablement.
// The Hyprland behavior itself is registered by the loader in hypr/.
QtObject {
  readonly property string pluginId: "roubilibo.windows-new-workspace"
}
