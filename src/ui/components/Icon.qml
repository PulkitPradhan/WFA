pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

Text {
    id: root

    property string name: ""
    property int size: 20

    text: name
    font.family: Theme.fonts.familyIcon
    font.pixelSize: size
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
