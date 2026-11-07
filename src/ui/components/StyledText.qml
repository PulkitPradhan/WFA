pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

Text {
    id: root

    color: Theme.text
    font.family: Theme.fonts.family
    font.pixelSize: Theme.fonts.normal
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim.normal
            easing.type: Theme.anim.easingCurve
        }
    }
}
