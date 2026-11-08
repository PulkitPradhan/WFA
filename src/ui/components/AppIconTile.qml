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
    property int iconSize: 52

    signal clicked()

    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isPressed: mouseArea.pressed

    Layout.fillWidth: true
    Layout.preferredHeight: 88
    radius: Theme.rounding.lg
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
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.clicked();
            if (root.execCmd) {
                Quickshell.execDetached(["sh", "-c", root.execCmd]);
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6
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
            font.pixelSize: 11
            font.weight: root.isHovered ? Font.Medium : Font.Normal
            color: root.isHovered ? Theme.text : Theme.textSecondary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
