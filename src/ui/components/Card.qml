pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

Rectangle {
    id: root

    // Matches Caelestia's layer transparency (0.40) to let Hyprland frosted-glass blur show through
    property real baseOpacity: Theme.transparency.layers + 0.05
    property bool hoverable: false
    readonly property bool isHovered: hoverArea.containsMouse

    color: Theme.alpha(Theme.surfaceContainer, baseOpacity)
    radius: Theme.rounding.xl
    border.color: Theme.alpha(Theme.outlineVariant, isHovered ? 0.35 : 0.12)
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
