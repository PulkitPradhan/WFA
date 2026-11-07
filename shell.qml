//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "src/ui"

ShellRoot {
    id: root

    // Load Caelestia's exact typography (Google Sans Flex variable font)
    FontLoader {
        id: gsfLoader
        source: Quickshell.shellPath("assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    DesktopLayer {
        id: desktopLayer
    }
}
