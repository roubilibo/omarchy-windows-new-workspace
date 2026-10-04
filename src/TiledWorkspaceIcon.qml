import QtQuick
import QtQuick.Shapes
import qs.Commons

Item {
  id: root

  required property bool featureEnabled
  required property color foregroundColor

  readonly property color accentColor: foregroundColor
  readonly property color accentColor2: foregroundColor
  readonly property color backFrameColor: foregroundColor
  readonly property color plusColor: featureEnabled ? Color.accent : Color.muted
  readonly property color tileLeftColor: Qt.darker(foregroundColor, 1.25)
  readonly property color tileRightColor: Qt.darker(foregroundColor, 1.55)
  readonly property color backgroundColor: Color.background

  Item {
    id: icon
    width: 191
    height: 160
    anchors.centerIn: parent
    // Fit the complete artwork bounds into the bar's optical icon area.
    scale: Math.min(root.width / 191, root.height / 160)
    transformOrigin: Item.Center

    // Back workspace outline, intentionally visible only in part.
    Shape {
      id: backWorkspace
      visible: root.featureEnabled
      x: 34
      y: 24
      width: 142
      height: 105

      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        strokeColor: root.backFrameColor
        strokeWidth: 9
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        startX: 3.5
        startY: 28
        PathLine { x: 3.5; y: 15 }
        PathCubic {
          x: 15; y: 3.5
          control1X: 3.5; control1Y: 8.35
          control2X: 8.35; control2Y: 3.5
        }
        PathLine { x: 88; y: 3.5 }
      }

      ShapePath {
        strokeColor: root.backFrameColor
        strokeWidth: 9
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        startX: 138.5
        startY: 30
        PathLine { x: 138.5; y: 90 }
        PathCubic {
          x: 127; y: 101.5
          control1X: 138.5; control1Y: 96.35
          control2X: 131.85; control2Y: 101.5
        }
        // Extend under the front workspace so the exposed line meets
        // its right edge instead of floating beside it.
        PathLine { x: 80; y: 101.5 }
      }
    }

    // Standalone plus, matching the supplied design.
    Item {
      visible: root.featureEnabled
      x: 145; y: 5; width: 36; height: 36
      Rectangle {
        anchors.centerIn: parent
        width: 36; height: 9
        radius: height / 2
        color: root.plusColor
      }
      Rectangle {
        anchors.centerIn: parent
        width: 9; height: 36
        radius: width / 2
        color: root.plusColor
      }
    }

    // Main tiled workspace.
    Rectangle {
      id: workspaceOuter
      width: root.featureEnabled ? 142 : 180
      height: root.featureEnabled ? 105 : 133
      x: root.featureEnabled ? 10 : (icon.width - width) / 2
      y: root.featureEnabled ? 48 : (icon.height - height) / 2
      radius: root.featureEnabled ? 15 : 20
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: root.accentColor }
        GradientStop { position: 1.0; color: root.accentColor2 }
      }

      Rectangle {
        id: workspaceInner
        anchors.fill: parent
        anchors.margins: 10
        radius: Math.max(1, workspaceOuter.radius - 10)
        color: root.backgroundColor

        Rectangle {
          id: leftTile
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.leftMargin: 8
          anchors.topMargin: 8
          anchors.bottomMargin: 8
          width: root.featureEnabled ? 60 : 80
          radius: 6
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.tileLeftColor, 1.08) }
            GradientStop { position: 1.0; color: root.tileLeftColor }
          }
        }

        Rectangle {
          id: topRightTile
          anchors.left: leftTile.right
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          anchors.topMargin: 8
          height: root.featureEnabled ? 35 : 49
          radius: 6
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.tileRightColor, 1.05) }
            GradientStop { position: 1.0; color: root.tileRightColor }
          }
        }

        Rectangle {
          anchors.left: leftTile.right
          anchors.right: parent.right
          anchors.top: topRightTile.bottom
          anchors.bottom: parent.bottom
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          anchors.topMargin: 8
          anchors.bottomMargin: 8
          radius: 6
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.tileRightColor, 1.05) }
            GradientStop { position: 1.0; color: root.tileRightColor }
          }
        }
      }
    }
  }
}
