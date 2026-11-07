//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "src/ui"

ShellRoot {
    id: root

    DesktopLayer {
        id: desktopLayer
    }
}
