pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property int currentIndex: 0
    property var card: null
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
                id: todayArea
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
                        if (root.currentIndex !== 0) {
                            root.currentIndex = 0;
                            root.selectionChanged(0);
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
                id: weekArea
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
                        if (root.currentIndex !== 1) {
                            root.currentIndex = 1;
                            root.selectionChanged(1);
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
        }
    }
}
