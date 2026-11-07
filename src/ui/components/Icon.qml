pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

Text {
    id: root

    property string name: ""
    property int size: 20
    property real fill: 1.0

    text: name
    font.family: Theme.fonts.familyIcon
    font.pixelSize: size
    font.variableAxes: ({ "FILL": root.fill, "opsz": root.size })
    color: Theme.onSurfaceVariant
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim.normal
            easing.type: Theme.anim.easingCurve
        }
    }
}
