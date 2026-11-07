pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

Rectangle {
    id: root

    property real baseOpacity: 0.72
    property bool hoverable: false
    readonly property bool isHovered: hoverArea.containsMouse

    color: Theme.alpha(Theme.surfaceContainer, baseOpacity)
    radius: Theme.rounding.lg
    border.color: Theme.alpha(Theme.outlineVariant, isHovered ? 0.6 : 0.3)
    border.width: 1

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim.normal
            easing.type: Theme.anim.easingCurve
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.anim.fast
            easing.type: Theme.anim.easingCurve
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: root.hoverable
        hoverEnabled: root.hoverable
        acceptedButtons: Qt.NoButton
    }
}
