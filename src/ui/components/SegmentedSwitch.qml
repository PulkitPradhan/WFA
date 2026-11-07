pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property int currentIndex: 0
    signal selectionChanged(int index)

    width: 114
    height: 26
    radius: Theme.rounding.full
    color: Theme.alpha(Theme.surfaceVariant, 0.35)
    border.color: Theme.alpha(Theme.outlineVariant, 0.15)
    border.width: 1

    // Sliding indicator pill
    Rectangle {
        id: indicator
        width: (root.width - 4) / 2
        height: root.height - 4
        y: 2
        x: root.currentIndex === 0 ? 2 : (root.width / 2)
        radius: Theme.rounding.full
        color: Theme.primary

        Behavior on x {
            NumberAnimation {
                duration: Theme.anim.normal
                easing.type: Theme.anim.easingCurve
            }
        }
    }

    Row {
        anchors.fill: parent

        // Option 0: Today
        Item {
            width: parent.width / 2
            height: parent.height

            StyledText {
                anchors.centerIn: parent
                text: "Today"
                font.pixelSize: 11
                font.weight: root.currentIndex === 0 ? Font.Bold : Font.Medium
                color: root.currentIndex === 0 ? Theme.textOnPrimary : Theme.textSecondary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.currentIndex !== 0) {
                        root.currentIndex = 0;
                        root.selectionChanged(0);
                    }
                }
            }
        }

        // Option 1: Week
        Item {
            width: parent.width / 2
            height: parent.height

            StyledText {
                anchors.centerIn: parent
                text: "Week"
                font.pixelSize: 11
                font.weight: root.currentIndex === 1 ? Font.Bold : Font.Medium
                color: root.currentIndex === 1 ? Theme.textOnPrimary : Theme.textSecondary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.currentIndex !== 1) {
                        root.currentIndex = 1;
                        root.selectionChanged(1);
                    }
                }
            }
        }
    }
}
