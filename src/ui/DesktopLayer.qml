pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "components"

PanelWindow {
    id: win

    screen: Quickshell.screens[0]
    color: "transparent"

    // Wayland ARGB buffer format: allows transparent background and Hyprland frosted-glass blur
    surfaceFormat.opaque: false

    // --- Wayland Layer Shell Configuration ---
    // WlrLayer.Bottom places widgets directly on the desktop plane (above wallpaper, beneath application windows)
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "caelestia-desktop-widgets"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Hyprland compositor blur applied to our layer namespace
    Component.onCompleted: {
        Quickshell.execDetached(["hyprctl", "--batch", "eval hl.layer_rule({ match = { namespace = '^caelestia-desktop-widgets$' }, blur = true, ignore_alpha = 0.15 })"]);
    }

    // --- Precision Input Masking (Click-Through) ---
    // Only the 4 individual compartment cards capture pointer events.
    // All transparent desktop areas between and around them pass mouse events straight through to the desktop.
    mask: Region {
        Region { item: timeCard }
        Region { item: musicCard }
        Region { item: screenTimeCard }
        Region { item: appDrawerCard }
    }

    // Live clock ticker
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }
    property var currentTime: new Date()

    // --- Central Widget Cluster ---
    // Recreates the Excalidraw design: Left column (3 stacked compartments) + Right column (tall drawer)
    Row {
        id: cluster
        anchors.centerIn: parent
        spacing: Theme.spacing.xl

        // ==========================================
        // LEFT COLUMN (3 STACKED COMPARTMENTS)
        // ==========================================
        Column {
            id: leftCol
            width: 520
            spacing: Theme.spacing.lg

            // ------------------------------------------
            // 1. TOP COMPARTMENT: Clock & Date
            // ------------------------------------------
            Card {
                id: timeCard
                width: parent.width
                height: 180
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.xl
                    spacing: Theme.spacing.sm

                    // Top Bar: Weather Chip
                    RowLayout {
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 26
                            radius: Theme.rounding.full
                            color: Theme.alpha(Theme.surfaceVariant, 0.40)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.30)
                            border.width: 1
                            Layout.preferredWidth: weatherRow.implicitWidth + 20

                            Row {
                                id: weatherRow
                                anchors.centerIn: parent
                                spacing: 6

                                Icon {
                                    name: "wb_sunny"
                                    size: 14
                                    color: Theme.primary
                                }

                                StyledText {
                                    text: "24°C Clear"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.onSurfaceVariant
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Caelestia Shell Clock Layout
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: Theme.spacing.lg

                        // Hour : Minute Block
                        RowLayout {
                            spacing: Theme.spacing.xs

                            StyledText {
                                text: Qt.formatTime(win.currentTime, "hh")
                                font.pixelSize: 62
                                font.weight: Font.Bold
                                color: Theme.primary
                            }

                            StyledText {
                                text: ":"
                                font.pixelSize: 58
                                font.weight: Font.DemiBold
                                color: Theme.tertiary
                                opacity: 0.8
                                Layout.topMargin: -4
                            }

                            StyledText {
                                text: Qt.formatTime(win.currentTime, "mm")
                                font.pixelSize: 62
                                font.weight: Font.Bold
                                color: Theme.secondary
                            }
                        }

                        // Vertical Accent Divider Pill
                        Rectangle {
                            Layout.preferredHeight: 56
                            Layout.preferredWidth: 4
                            radius: Theme.rounding.full
                            color: Theme.primary
                            opacity: 0.8
                        }

                        // Date Column
                        ColumnLayout {
                            spacing: 0

                            StyledText {
                                text: Qt.formatDate(win.currentTime, "MMMM").toUpperCase()
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                font.letterSpacing: 3
                                color: Theme.secondary
                            }

                            StyledText {
                                text: Qt.formatDate(win.currentTime, "dd")
                                font.pixelSize: 22
                                font.weight: Font.Medium
                                font.letterSpacing: 1
                                color: Theme.primary
                            }

                            StyledText {
                                text: Qt.formatDate(win.currentTime, "dddd")
                                font.pixelSize: 13
                                font.letterSpacing: 1
                                color: Theme.onSurfaceVariant
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ------------------------------------------
            // 2. MIDDLE COMPARTMENT: Spotify Mini-Player
            // ------------------------------------------
            Card {
                id: musicCard
                width: parent.width
                height: 98
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.lg
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.md

                        // Album Art / Music Icon Tile
                        Rectangle {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            radius: Theme.rounding.lg
                            color: Theme.alpha(Theme.primary, 0.16)
                            border.color: Theme.alpha(Theme.primary, 0.35)
                            border.width: 1

                            Icon {
                                anchors.centerIn: parent
                                name: "music_note"
                                size: 26
                                color: Theme.primary
                            }
                        }

                        // Track Title & Artist
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            StyledText {
                                text: "Wish I had blue eyes"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: Theme.primary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: "N4meless • Spotify"
                                font.pixelSize: 12
                                color: Theme.onSurfaceVariant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Playback Controls: [<-] [play/pause] [->]
                        Row {
                            spacing: Theme.spacing.sm
                            Layout.alignment: Qt.AlignVCenter

                            // Prev button
                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.surfaceVariant, 0.50)
                                border.color: Theme.alpha(Theme.outlineVariant, 0.35)
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip_previous"
                                    size: 18
                                    color: Theme.onSurface
                                }
                            }

                            // Play/Pause pill button
                            Rectangle {
                                width: 54
                                height: 36
                                radius: Theme.rounding.full
                                color: Theme.primary
                                border.color: Theme.alpha(Theme.primary, 0.85)
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: "pause"
                                    size: 20
                                    color: Theme.onPrimary
                                }
                            }

                            // Next button
                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.surfaceVariant, 0.50)
                                border.color: Theme.alpha(Theme.outlineVariant, 0.35)
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip_next"
                                    size: 18
                                    color: Theme.onSurface
                                }
                            }
                        }
                    }

                    // Progress track
                    Rectangle {
                        Layout.fillWidth: true
                        height: 3
                        radius: Theme.rounding.full
                        color: Theme.alpha(Theme.outlineVariant, 0.35)

                        Rectangle {
                            width: parent.width * 0.42
                            height: parent.height
                            radius: Theme.rounding.full
                            color: Theme.primary
                        }
                    }
                }
            }

            // ------------------------------------------
            // 3. BOTTOM COMPARTMENT: Screen Time
            // ------------------------------------------
            Card {
                id: screenTimeCard
                width: parent.width
                height: 290
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.xl
                    spacing: Theme.spacing.md

                    // Header row
                    RowLayout {
                        Layout.fillWidth: true

                        Row {
                            spacing: Theme.spacing.sm
                            Icon {
                                name: "hourglass_top"
                                size: 16
                                color: Theme.primary
                            }
                            StyledText {
                                text: "SCREEN TIME"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.letterSpacing: 1.5
                                color: Theme.primary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 24
                            radius: Theme.rounding.full
                            color: Theme.alpha(Theme.primary, 0.16)
                            border.color: Theme.alpha(Theme.primary, 0.35)
                            border.width: 1
                            Layout.preferredWidth: stBadgeRow.implicitWidth + 16

                            Row {
                                id: stBadgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                Icon {
                                    name: "query_builder"
                                    size: 12
                                    color: Theme.primary
                                }
                                StyledText {
                                    text: "4h 28m today"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.primary
                                }
                            }
                        }
                    }

                    // Application Usage Rows
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // App 1: Zen Browser
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                IconImage {
                                    source: Quickshell.iconPath("zen-browser", "web-browser")
                                    implicitSize: 18
                                }
                                StyledText {
                                    text: "Zen Browser"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Theme.onSurface
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    text: "2h 14m (50%)"
                                    font.pixelSize: 11
                                    color: Theme.onSurfaceVariant
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.outlineVariant, 0.3)
                                Rectangle {
                                    width: parent.width * 0.50
                                    height: parent.height
                                    radius: Theme.rounding.full
                                    color: Theme.primary
                                }
                            }
                        }

                        // App 2: Visual Studio Code
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                IconImage {
                                    source: Quickshell.iconPath("vscode", "text-editor")
                                    implicitSize: 18
                                }
                                StyledText {
                                    text: "Visual Studio Code"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Theme.onSurface
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    text: "1h 18m (29%)"
                                    font.pixelSize: 11
                                    color: Theme.onSurfaceVariant
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.outlineVariant, 0.3)
                                Rectangle {
                                    width: parent.width * 0.29
                                    height: parent.height
                                    radius: Theme.rounding.full
                                    color: Theme.secondary
                                }
                            }
                        }

                        // App 3: Kitty Terminal
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                IconImage {
                                    source: Quickshell.iconPath("kitty", "utilities-terminal")
                                    implicitSize: 18
                                }
                                StyledText {
                                    text: "Kitty Terminal"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Theme.onSurface
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    text: "38m (14%)"
                                    font.pixelSize: 11
                                    color: Theme.onSurfaceVariant
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.outlineVariant, 0.3)
                                Rectangle {
                                    width: parent.width * 0.14
                                    height: parent.height
                                    radius: Theme.rounding.full
                                    color: Theme.tertiary
                                }
                            }
                        }

                        // App 4: Spotify
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                IconImage {
                                    source: Quickshell.iconPath("spotify", "audio-player")
                                    implicitSize: 18
                                }
                                StyledText {
                                    text: "Spotify"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Theme.onSurface
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    text: "18m (7%)"
                                    font.pixelSize: 11
                                    color: Theme.onSurfaceVariant
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.outlineVariant, 0.3)
                                Rectangle {
                                    width: parent.width * 0.07
                                    height: parent.height
                                    radius: Theme.rounding.full
                                    color: Theme.outline
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ==========================================
        // RIGHT COLUMN (TALL APPLICATION DRAWER)
        // ==========================================
        Card {
            id: appDrawerCard
            width: 480
            // Exactly matches left column height: 180 + 16 + 98 + 16 + 290 = 600px
            height: 600
            radius: Theme.rounding.xl
            hoverable: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.padding.xl
                spacing: Theme.spacing.md

                // Header Bar: Clean title
                RowLayout {
                    Layout.fillWidth: true

                    Row {
                        spacing: Theme.spacing.sm
                        Icon {
                            name: "apps"
                            size: 18
                            color: Theme.primary
                        }
                        StyledText {
                            text: "APPLICATION DRAWER"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            color: Theme.primary
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Section 1 Label: "MOST USED"
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.xs
                    spacing: 6

                    StyledText {
                        text: "MOST USED"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                        color: Theme.onSurfaceVariant
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.alpha(Theme.outlineVariant, 0.3)
                    }
                }

                // 3x3 Most-Used App Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: [
                            { name: "Zen Browser", icon: "zen-browser", fallback: "web-browser", running: true },
                            { name: "Kitty", icon: "kitty", fallback: "utilities-terminal", running: true },
                            { name: "VS Code", icon: "vscode", fallback: "text-editor", running: true },
                            { name: "Discord", icon: "omarchy-discord", fallback: "chat", running: false },
                            { name: "Spotify", icon: "spotify", fallback: "audio-player", running: true },
                            { name: "Obsidian", icon: "obsidian", fallback: "text-editor", running: false },
                            { name: "Files", icon: "thunar", fallback: "system-file-manager", running: false },
                            { name: "Steam", icon: "steam", fallback: "applications-games", running: false },
                            { name: "Settings", icon: "org.gnome.Settings", fallback: "preferences-system", running: false }
                        ]

                        Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 82
                            radius: Theme.rounding.lg
                            color: itemMouseArea.containsMouse ? Theme.alpha(Theme.surfaceVariant, 0.6) : Theme.alpha(Theme.surfaceContainerLow, 0.4)
                            border.color: itemMouseArea.containsMouse ? Theme.alpha(Theme.primary, 0.5) : Theme.alpha(Theme.outlineVariant, 0.25)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.anim.fast } }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 5

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 32
                                    height: 32

                                    IconImage {
                                        anchors.centerIn: parent
                                        source: Quickshell.iconPath(modelData.icon, modelData.fallback)
                                        implicitSize: 32
                                    }

                                    // Running Indicator Dot
                                    Rectangle {
                                        visible: modelData.running
                                        width: 7
                                        height: 7
                                        radius: Theme.rounding.full
                                        color: Theme.primary
                                        border.color: Theme.surfaceContainer
                                        border.width: 1
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                    }
                                }

                                StyledText {
                                    text: modelData.name
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: itemMouseArea.containsMouse ? Theme.primary : Theme.onSurface
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Section 2 Label: "CUSTOM SHORTCUTS"
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        text: "CUSTOM SHORTCUTS"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                        color: Theme.onSurfaceVariant
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.alpha(Theme.outlineVariant, 0.3)
                    }
                }

                // Custom Shortcuts Row (4 tiles)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "Terminal", icon: "terminal", color: Theme.primary },
                            { label: "Files", icon: "folder", color: Theme.secondary },
                            { label: "Screenshot", icon: "screenshot_monitor", color: Theme.tertiary },
                            { label: "Settings", icon: "settings", color: Theme.outline }
                        ]

                        Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: Theme.rounding.md
                            color: shortcutArea.containsMouse ? Theme.alpha(Theme.surfaceVariant, 0.6) : Theme.alpha(Theme.surfaceContainerLow, 0.4)
                            border.color: shortcutArea.containsMouse ? Theme.alpha(modelData.color, 0.5) : Theme.alpha(Theme.outlineVariant, 0.25)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.anim.fast } }

                            MouseArea {
                                id: shortcutArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Icon {
                                    name: modelData.icon
                                    size: 16
                                    color: modelData.color
                                }

                                StyledText {
                                    text: modelData.label
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: shortcutArea.containsMouse ? Theme.onSurface : Theme.onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
