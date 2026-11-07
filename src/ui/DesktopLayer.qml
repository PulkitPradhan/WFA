pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../theme"
import "components"

PanelWindow {
    id: win

    screen: Quickshell.screens[0]
    color: "transparent"

    // Wayland ARGB buffer format: allows transparent background and Hyprland frosted-glass blur
    surfaceFormat.opaque: false

    // --- Wayland Layer Shell Configuration ---
    // WlrLayer.Bottom places widgets on the desktop plane (above wallpaper, beneath application windows)
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

    // Hyprland compositor blur rule assertion
    Component.onCompleted: {
        Quickshell.execDetached(["hyprctl", "--batch", "eval hl.layer_rule({ match = { namespace = '^caelestia-desktop-widgets$' }, blur = true, ignore_alpha = 0.15 })"]);
    }

    Connections {
        target: Theme
        function onSchemeNameChanged(): void {
            Quickshell.execDetached(["hyprctl", "--batch", "eval hl.layer_rule({ match = { namespace = '^caelestia-desktop-widgets$' }, blur = true, ignore_alpha = 0.15 })"]);
        }
    }

    // --- Precision Input Masking (Click-Through) ---
    // Pointer events are strictly restricted to the interactive widget cards.
    // All transparent desktop areas pass through directly to Hyprland.
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

    // Native MPRIS discovery for Spotify
    readonly property var activePlayers: Mpris.players.values
    readonly property MprisPlayer spotifyPlayer: {
        for (let i = 0; i < activePlayers.length; i++) {
            const p = activePlayers[i];
            if (p && p.identity && p.identity.toLowerCase().includes("spotify")) {
                return p;
            }
        }
        return activePlayers.length > 0 ? activePlayers[0] : null;
    }

    readonly property bool isPlaying: spotifyPlayer
        ? (spotifyPlayer.playbackState === MprisPlaybackState.Playing)
        : false

    readonly property string trackTitle: (spotifyPlayer && spotifyPlayer.trackTitle)
        ? spotifyPlayer.trackTitle
        : "leaveamsg"

    readonly property string trackArtist: (spotifyPlayer && spotifyPlayer.trackArtist)
        ? spotifyPlayer.trackArtist
        : "morgue • Spotify"

    readonly property string trackArtUrl: (spotifyPlayer && spotifyPlayer.trackArtUrl)
        ? spotifyPlayer.trackArtUrl
        : ""

    // Live position tracking for MPRIS player
    Timer {
        interval: 1000
        running: win.isPlaying
        repeat: true
        onTriggered: {
            if (win.spotifyPlayer) {
                win.spotifyPlayer.positionChanged();
            }
        }
    }

    readonly property real trackPosSec: {
        const p = win.spotifyPlayer;
        if (!p || !p.position) return 84; // fallback preview 1:24
        return p.position > 100000 ? (p.position / 1000000) : p.position;
    }

    readonly property real trackLenSec: {
        const p = win.spotifyPlayer;
        if (!p || !p.length) return 225; // fallback preview 3:45
        return p.length > 100000 ? (p.length / 1000000) : p.length;
    }

    readonly property real trackProgress: (trackLenSec > 0)
        ? Math.min(1.0, Math.max(0.0, trackPosSec / trackLenSec))
        : 0.37

    function formatTime(secs: real): string {
        if (!secs || secs <= 0 || isNaN(secs)) return "0:00";
        const total = Math.floor(secs);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Screen-time view state: 0 = Today, 1 = Week
    property int screenTimeView: 0

    // ==========================================
    // CENTRAL WIDGET CLUSTER (1920x1080 Balanced)
    // ==========================================
    Row {
        id: cluster
        anchors.centerIn: parent
        spacing: 16

        // ==========================================
        // LEFT COLUMN (Clock + Spotify + Screen Time)
        // ==========================================
        Column {
            id: leftCol
            width: 480
            spacing: 14

            // ------------------------------------------
            // 1. CLOCK & DATE COMPARTMENT
            // ------------------------------------------
            Card {
                id: timeCard
                width: parent.width
                height: 182
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 4

                    // Subtle Top Bar: Weather Indicator
                    RowLayout {
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 24
                            radius: Theme.rounding.full
                            color: Theme.alpha(Theme.surfaceVariant, 0.35)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1
                            Layout.preferredWidth: weatherRow.implicitWidth + 18

                            Row {
                                id: weatherRow
                                anchors.centerIn: parent
                                spacing: 5

                                Icon {
                                    name: "wb_sunny"
                                    size: 14
                                    color: Theme.primary
                                }

                                StyledText {
                                    text: "24°C Clear"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.textSecondary
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Prominent Caelestia Typography Clock (Using Caelestia's Rubik clock token)
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: 16

                        // Primary Clock Display
                        RowLayout {
                            spacing: 2

                            StyledText {
                                text: Qt.formatTime(win.currentTime, "hh")
                                font.family: Theme.fonts.familyClock
                                font.pixelSize: 64
                                font.weight: Font.Bold
                                color: Theme.primary
                            }

                            StyledText {
                                text: ":"
                                font.family: Theme.fonts.familyClock
                                font.pixelSize: 58
                                font.weight: Font.DemiBold
                                color: Theme.primaryFixed
                                opacity: 0.9
                                Layout.topMargin: -4
                            }

                            StyledText {
                                text: Qt.formatTime(win.currentTime, "mm")
                                font.family: Theme.fonts.familyClock
                                font.pixelSize: 64
                                font.weight: Font.Bold
                                color: Theme.text
                            }
                        }

                        // Vertical Accent Divider Pill
                        Rectangle {
                            Layout.preferredHeight: 56
                            Layout.preferredWidth: 3.5
                            radius: Theme.rounding.full
                            color: Theme.primary
                            opacity: 0.85
                        }

                        // Date Stack
                        ColumnLayout {
                            spacing: 1

                            StyledText {
                                text: Qt.formatDate(win.currentTime, "MMMM").toUpperCase()
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                font.letterSpacing: 2
                                color: Theme.primaryFixed
                            }

                            StyledText {
                                text: Qt.formatDate(win.currentTime, "dd")
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                font.letterSpacing: 1
                                color: Theme.primary
                            }

                            StyledText {
                                text: Qt.formatDate(win.currentTime, "dddd")
                                font.pixelSize: 13
                                font.letterSpacing: 1
                                color: Theme.textSecondary
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ------------------------------------------
            // 2. SPOTIFY MINI-PLAYER (Native MPRIS)
            // ------------------------------------------
            Card {
                id: musicCard
                width: parent.width
                height: 112
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        // Album Artwork Container
                        Rectangle {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            radius: Theme.rounding.md
                            color: Theme.alpha(Theme.surfaceVariant, 0.45)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.20)
                            border.width: 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                visible: win.trackArtUrl.length > 0
                                source: win.trackArtUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Icon {
                                anchors.centerIn: parent
                                visible: win.trackArtUrl.length === 0
                                name: "music_note"
                                size: 28
                                color: Theme.primary
                            }
                        }

                        // Track Title & Artist Metadata
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            StyledText {
                                text: win.trackTitle
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: win.trackArtist
                                font.pixelSize: 12
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Playback Controls [<-] [play/pause] [->] (Native Caelestia IconButton styling)
                        Row {
                            spacing: 8
                            Layout.alignment: Qt.AlignVCenter

                            // Previous Track Button
                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.rounding.full
                                color: prevArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.90) : Theme.alpha(Theme.surfaceContainerHigh, 0.55)
                                scale: prevArea.pressed ? 0.92 : (prevArea.containsMouse ? 1.06 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip_previous"
                                    size: 19
                                    color: Theme.text
                                }

                                MouseArea {
                                    id: prevArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (win.spotifyPlayer) win.spotifyPlayer.previous();
                                        else Quickshell.execDetached(["playerctl", "--player=spotify", "previous"]);
                                    }
                                }
                            }

                            // Play/Pause Accent Pill Button (Caelestia Stadium Morph)
                            Rectangle {
                                width: 58
                                height: 36
                                radius: Theme.rounding.full
                                color: Theme.primary
                                scale: playArea.pressed ? 0.92 : (playArea.containsMouse ? 1.05 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 120 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: win.isPlaying ? "pause" : "play_arrow"
                                    size: 20
                                    color: Theme.textOnPrimary
                                }

                                MouseArea {
                                    id: playArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (win.spotifyPlayer) win.spotifyPlayer.togglePlaying();
                                        else Quickshell.execDetached(["playerctl", "--player=spotify", "play-pause"]);
                                    }
                                }
                            }

                            // Next Track Button
                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.rounding.full
                                color: nextArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.90) : Theme.alpha(Theme.surfaceContainerHigh, 0.55)
                                scale: nextArea.pressed ? 0.92 : (nextArea.containsMouse ? 1.06 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip_next"
                                    size: 19
                                    color: Theme.text
                                }

                                MouseArea {
                                    id: nextArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (win.spotifyPlayer) win.spotifyPlayer.next();
                                        else Quickshell.execDetached(["playerctl", "--player=spotify", "next"]);
                                    }
                                }
                            }
                        }
                    }

                    // Progress Track with Technical Timers (Matching Caelestia Media Bar)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: win.formatTime(win.trackPosSec)
                            font.pixelSize: 10
                            font.family: Theme.fonts.familyMono
                            color: Theme.textSecondary
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: Theme.rounding.full
                            color: Theme.alpha(Theme.secondaryContainer, 0.45)

                            Rectangle {
                                width: parent.width * win.trackProgress
                                height: parent.height
                                radius: Theme.rounding.full
                                color: Theme.primary

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        StyledText {
                            text: win.formatTime(win.trackLenSec)
                            font.pixelSize: 10
                            font.family: Theme.fonts.familyMono
                            color: Theme.textSecondary
                        }
                    }
                }
            }

            // ------------------------------------------
            // 3. SCREEN TIME COMPARTMENT
            // ------------------------------------------
            Card {
                id: screenTimeCard
                width: parent.width
                height: 298
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Header Row with Title + Segmented Switch + Total Time Badge
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Row {
                            spacing: 6
                            Icon {
                                name: "schedule"
                                size: 16
                                color: Theme.primary
                            }
                            StyledText {
                                text: "Screen Time"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.text
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Daily / Weekly View Switch
                        SegmentedSwitch {
                            currentIndex: win.screenTimeView
                            onSelectionChanged: function(idx) { win.screenTimeView = idx; }
                        }

                        // Total Duration Badge
                        Rectangle {
                            height: 26
                            radius: Theme.rounding.full
                            color: Theme.alpha(Theme.primary, 0.14)
                            border.color: Theme.alpha(Theme.primary, 0.25)
                            border.width: 1
                            Layout.preferredWidth: stTotalText.implicitWidth + 16

                            StyledText {
                                id: stTotalText
                                anchors.centerIn: parent
                                text: win.screenTimeView === 0 ? "4h 28m" : "28h 15m"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.primary
                            }
                        }
                    }

                    // Application Usage Rows (Filtered dynamically by Today/Week)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: win.screenTimeView === 0 ? [
                                { name: "Zen Browser", icon: "zen-browser", fallback: "web-browser", time: "2h 14m", pct: 0.50, color: Theme.primary },
                                { name: "Visual Studio Code", icon: "vscode", fallback: "text-editor", time: "1h 18m", pct: 0.29, color: Theme.secondary },
                                { name: "Kitty Terminal", icon: "kitty", fallback: "utilities-terminal", time: "38m", pct: 0.14, color: Theme.tertiary },
                                { name: "Spotify", icon: "spotify", fallback: "audio-player", time: "18m", pct: 0.07, color: Theme.outline }
                            ] : [
                                { name: "Visual Studio Code", icon: "vscode", fallback: "text-editor", time: "12h 40m", pct: 0.45, color: Theme.primary },
                                { name: "Zen Browser", icon: "zen-browser", fallback: "web-browser", time: "9h 20m", pct: 0.33, color: Theme.secondary },
                                { name: "Kitty Terminal", icon: "kitty", fallback: "utilities-terminal", time: "4h 10m", pct: 0.15, color: Theme.tertiary },
                                { name: "Spotify", icon: "spotify", fallback: "audio-player", time: "2h 05m", pct: 0.07, color: Theme.outline }
                            ]

                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true

                                    IconImage {
                                        source: Quickshell.iconPath(modelData.icon, modelData.fallback)
                                        implicitSize: 18
                                    }

                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Theme.text
                                    }

                                    Item { Layout.fillWidth: true }

                                    StyledText {
                                        text: modelData.time + " (" + Math.round(modelData.pct * 100) + "%)"
                                        font.pixelSize: 11
                                        font.family: Theme.fonts.familyMono
                                        color: Theme.textSecondary
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 4
                                    radius: Theme.rounding.full
                                    color: Theme.alpha(Theme.secondaryContainer, 0.45)

                                    Rectangle {
                                        width: parent.width * modelData.pct
                                        height: parent.height
                                        radius: Theme.rounding.full
                                        color: modelData.color

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: Theme.anim.normal
                                                easing.type: Theme.anim.easingCurve
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ==========================================
        // RIGHT COLUMN: ICON-FIRST APPLICATION DRAWER
        // ==========================================
        Card {
            id: appDrawerCard
            width: 530
            // Height spans left column exact height: 182 + 14 + 112 + 14 + 298 = 620px
            height: 620
            radius: Theme.rounding.xl
            hoverable: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // Header Bar: Minimal & Native
                RowLayout {
                    Layout.fillWidth: true

                    Row {
                        spacing: 8
                        Icon {
                            name: "apps"
                            size: 19
                            color: Theme.primary
                        }
                        StyledText {
                            text: "Applications"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Count Badge
                    Rectangle {
                        height: 22
                        radius: Theme.rounding.full
                        color: Theme.alpha(Theme.surfaceVariant, 0.35)
                        border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                        border.width: 1
                        Layout.preferredWidth: countText.implicitWidth + 14

                        StyledText {
                            id: countText
                            anchors.centerIn: parent
                            text: "12 Most Used"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.textSecondary
                        }
                    }
                }

                // Section 1 Label: MOST USED
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Layout.topMargin: 2

                    StyledText {
                        text: "MOST USED"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Theme.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.alpha(Theme.outlineVariant, 0.15)
                    }
                }

                // 4x3 Icon-First Grid (Large 50px Native Icons, Clean, Borderless)
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: [
                            { name: "Zen Browser", icon: "zen-browser", fallback: "web-browser", exec: "zen-browser", running: true },
                            { name: "Kitty", icon: "kitty", fallback: "utilities-terminal", exec: "kitty", running: true },
                            { name: "VS Code", icon: "vscode", fallback: "text-editor", exec: "code", running: true },
                            { name: "Discord", icon: "omarchy-discord", fallback: "chat", exec: "discord", running: false },
                            { name: "Spotify", icon: "spotify", fallback: "audio-player", exec: "spotify", running: true },
                            { name: "Obsidian", icon: "obsidian", fallback: "text-editor", exec: "obsidian", running: false },
                            { name: "Files", icon: "thunar", fallback: "system-file-manager", exec: "thunar", running: false },
                            { name: "Steam", icon: "steam", fallback: "applications-games", exec: "steam", running: false },
                            { name: "Neovim", icon: "nvim", fallback: "utilities-terminal", exec: "kitty -e nvim", running: false },
                            { name: "Brave", icon: "brave-browser", fallback: "web-browser", exec: "brave", running: false },
                            { name: "OBS Studio", icon: "com.obsproject.Studio", fallback: "video-display", exec: "obs", running: false },
                            { name: "Settings", icon: "org.gnome.Settings", fallback: "preferences-system", exec: "omarchy menu toggle", running: false }
                        ]

                        AppIconTile {
                            required property var modelData
                            name: modelData.name
                            icon: modelData.icon
                            fallback: modelData.fallback
                            execCmd: modelData.exec
                            running: modelData.running
                            iconSize: 50
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Section 2 Label: CUSTOM SHORTCUTS
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: "CUSTOM SHORTCUTS"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Theme.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.alpha(Theme.outlineVariant, 0.15)
                    }
                }

                // Custom Shortcuts Row (4 Distinct Action Tiles)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "Terminal", icon: "terminal", color: Theme.primary, exec: "kitty" },
                            { label: "Files", icon: "folder", color: Theme.secondary, exec: "thunar" },
                            { label: "Screenshot", icon: "screenshot_monitor", color: Theme.tertiary, exec: "qs ipc -c caelestia call picker openClip || grim" },
                            { label: "Settings", icon: "settings", color: Theme.outline, exec: "omarchy menu toggle || systemsettings" }
                        ]

                        Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: Theme.rounding.md
                            color: shortcutArea.containsMouse ? Theme.alpha(Theme.surfaceVariant, 0.60) : Theme.alpha(Theme.surfaceContainerLow, 0.35)
                            border.color: shortcutArea.containsMouse ? Theme.alpha(modelData.color, 0.45) : Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1
                            scale: shortcutArea.pressed ? 0.95 : (shortcutArea.containsMouse ? 1.03 : 1.0)

                            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.anim.fast } }
                            Behavior on scale { NumberAnimation { duration: 120 } }

                            MouseArea {
                                id: shortcutArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.exec) {
                                        Quickshell.execDetached(["sh", "-c", modelData.exec]);
                                    }
                                }
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
                                    color: shortcutArea.containsMouse ? Theme.text : Theme.textSecondary
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
