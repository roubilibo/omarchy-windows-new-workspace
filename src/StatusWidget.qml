import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "roubilibo.windows-new-workspace"

  readonly property string stateFile: {
    var stateHome = Quickshell.env("XDG_STATE_HOME")
    if (!stateHome) stateHome = Quickshell.env("HOME") + "/.local/state"
    return stateHome + "/omarchy/windows-new-workspace"
  }
  property bool featureEnabled: true
  property bool keepTerminal: false
  property bool menuOpen: false
  property FileView stateView: FileView {
    path: root.stateFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.readState(text())
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function readState(raw) {
    var values = String(raw || "").trim().split(/\s+/)
    if (values[0] === "true") root.featureEnabled = true
    else if (values[0] === "false") root.featureEnabled = false
    root.keepTerminal = values[1] === "true"
  }

  function close() {
    menuOpen = false
  }

  Process {
    id: toggleProcess
    command: ["hyprctl", "eval", "_G.__windows_new_workspace_toggle()"]
  }

  Process {
    id: keepTerminalProcess
    command: ["hyprctl", "eval", "_G.__windows_new_workspace_toggle_keep_terminal()"]
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    opticalSize: Style.bar.iconCanvas
    active: root.featureEnabled
    activeColor: button.foreground
    useActiveColor: true
    tooltipText: "New tiled windows on new workspace: "
      + (root.featureEnabled ? "ON" : "OFF")
    iconComponent: Component {
      TiledWorkspaceIcon {
        anchors.fill: parent
        featureEnabled: root.featureEnabled
        foregroundColor: button.foreground
      }
    }
    onPressed: function(button) {
      if (button === Qt.LeftButton) {
        root.menuOpen = !root.menuOpen
      } else if (button === Qt.RightButton && !toggleProcess.running) {
        toggleProcess.running = true
      }
    }
  }

  PopupCard {
    id: optionsPopup
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.menuOpen
    contentWidth: optionsPopup.fittedContentWidth(Style.space(290))
    contentHeight: optionsPopup.fittedContentHeight(optionsColumn.implicitHeight)

    Column {
      id: optionsColumn
      anchors.fill: parent
      spacing: Style.space(8)

      Text {
        text: "Window behavior"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Toggle {
        width: optionsColumn.width
        label: "Keep terminal"
        description: "Keep new terminal windows on their opening workspace."
        checked: root.keepTerminal
        foreground: root.bar ? root.bar.foreground : Color.foreground
        onClicked: {
          if (!keepTerminalProcess.running)
            keepTerminalProcess.running = true
        }
      }
    }
  }
}
