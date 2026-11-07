pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

Text {
    id: root

    color: Theme.onSurface
    font.family: Theme.fonts.family
    font.pixelSize: Theme.fonts.body
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim.normal
            easing.type: Theme.anim.easingCurve
        }
    }
}
