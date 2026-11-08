pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../theme"

Rectangle {
    id: root

    property string name: ""
    property string icon: ""
    property string fallback: "application-x-executable"
    property string execCmd: ""
    property bool running: false
    property var card: null

    readonly property real tileWidth: width > 0 ? width : 100
    property int iconSize: Math.round(Math.min(72, Math.max(34, tileWidth * 0.48)))

    signal clicked()

    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isPressed: mouseArea.pressed

    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(tileWidth * 0.88)
    radius: Math.round(Math.min(20, Math.max(10, tileWidth * 0.15)))
    color: isPressed
        ? Theme.alpha(Theme.primary, 0.16)
        : (isHovered ? Theme.alpha(Theme.onSurface, 0.08) : "transparent")

    // Subtle scale feedback on hover and press
    scale: isPressed ? 0.94 : (isHovered ? 1.05 : 1.0)
    transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property real startScreenX: 0
        property real startScreenY: 0
        property bool isDragging: false

        onPressed: (mouse) => {
            isDragging = false;
            if (root.card && root.card.parent) {
                const p = mapToItem(root.card.parent, mouse.x, mouse.y);
                startScreenX = p.x;
                startScreenY = p.y;
            }
        }

        onPositionChanged: (mouse) => {
            if (pressed && root.card && root.card.parent) {
                const p = mapToItem(root.card.parent, mouse.x, mouse.y);
                if (!isDragging && (Math.abs(p.x - startScreenX) > 6 || Math.abs(p.y - startScreenY) > 6)) {
                    isDragging = true;
                    root.card.startMoving(startScreenX, startScreenY);
                }
                if (isDragging) {
                    root.card.moveWidget(p.x, p.y);
                }
            }
        }

        onReleased: (mouse) => {
            if (isDragging && root.card) {
                isDragging = false;
                root.card.stopMoving();
            } else if (!isDragging) {
                root.clicked();
                if (root.execCmd) {
                    Quickshell.execDetached(["sh", "-c", root.execCmd]);
                }
            }
        }

        onCanceled: {
            if (isDragging && root.card) {
                isDragging = false;
                root.card.stopMoving();
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Math.round(Math.max(3, tileWidth * 0.05))
        width: parent.width - 12

        Item {
            Layout.alignment: Qt.AlignHCenter
            width: root.iconSize
            height: root.iconSize

            IconImage {
                anchors.centerIn: parent
                source: root.icon ? (root.icon.startsWith("/") ? ("file://" + root.icon) : Quickshell.iconPath(root.icon, root.fallback)) : ""
                implicitSize: root.iconSize
            }
        }

        StyledText {
            text: root.name
            font.pixelSize: Math.round(Math.min(14, Math.max(9, root.tileWidth * 0.11)))
            font.weight: root.isHovered ? Font.Medium : Font.Normal
            color: root.isHovered ? Theme.text : Theme.textSecondary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
