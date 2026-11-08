pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../theme"
import "../services"
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

    // Weather expansion mode
    property bool showWeather: false

    // ==========================================
    // DYNAMIC MULTI-SOURCE MEDIA PLAYER ENGINE
    // ==========================================
    readonly property var playerList: Mpris.players.values
    readonly property int playerCount: playerList ? playerList.length : 0
    property int currentPlayerIndex: 0
    readonly property int clampedPlayerIndex: playerCount > 0 ? Math.min(Math.max(0, currentPlayerIndex), playerCount - 1) : 0
    readonly property MprisPlayer currentPlayer: playerCount > 0 ? playerList[clampedPlayerIndex] : null

    readonly property bool isPlaying: currentPlayer
        ? (currentPlayer.playbackState === MprisPlaybackState.Playing)
        : false

    readonly property string trackTitle: (currentPlayer && currentPlayer.trackTitle && currentPlayer.trackTitle.length > 0)
        ? currentPlayer.trackTitle
        : "No Media Playing"

    readonly property string trackArtist: (currentPlayer && currentPlayer.trackArtist && currentPlayer.trackArtist.length > 0)
        ? currentPlayer.trackArtist
        : (currentPlayer ? getPlayerIdentity(currentPlayer) : "Idle")

    readonly property string trackArtUrl: (currentPlayer && currentPlayer.trackArtUrl)
        ? currentPlayer.trackArtUrl
        : ""

    readonly property real playerVolume: (currentPlayer && currentPlayer.volume !== undefined)
        ? currentPlayer.volume
        : 1.0

    property real lastNonZeroVolume: 1.0

    readonly property int loopState: (currentPlayer && currentPlayer.loopState !== undefined)
        ? currentPlayer.loopState
        : 0

    readonly property bool isShuffle: (currentPlayer && currentPlayer.shuffle !== undefined)
        ? currentPlayer.shuffle
        : false

    function getPlayerIdentity(p: MprisPlayer): string {
        if (!p || !p.identity) return "Media Player";
        const id = p.identity.toLowerCase();
        if (id.includes("spotify")) return "Spotify";
        if (id.includes("chromium")) return "Chromium";
        if (id.includes("brave")) return "Brave";
        if (id.includes("firefox")) return "Firefox";
        if (id.includes("mpv")) return "MPV";
        if (id.includes("vlc")) return "VLC";
        return p.identity;
    }

    function getPlayerIcon(p: MprisPlayer): string {
        if (!p || !p.identity) return "multimedia-player";
        const id = p.identity.toLowerCase();
        if (id.includes("spotify")) return "spotify-client";
        if (id.includes("chromium")) return "chromium";
        if (id.includes("brave")) return "brave-desktop";
        if (id.includes("firefox")) return "firefox";
        return "multimedia-player";
    }

    // Live position tracking for MPRIS player
    Timer {
        interval: 1000
        running: win.isPlaying
        repeat: true
        onTriggered: {
            if (win.currentPlayer) {
                win.currentPlayer.positionChanged();
            }
        }
    }

    readonly property real trackPosSec: win.currentPlayer?.position ?? 0
    readonly property real trackLenSec: win.currentPlayer?.length ?? 0

    property bool isDraggingSeek: false
    property real dragSeekPos: 0.0

    readonly property real trackProgress: (trackLenSec > 0)
        ? Math.min(1.0, Math.max(0.0, trackPosSec / trackLenSec))
        : 0.0

    readonly property real displayProgress: isDraggingSeek
        ? (trackLenSec > 0 ? Math.min(1.0, Math.max(0.0, dragSeekPos / trackLenSec)) : 0.0)
        : trackProgress

    function seekTo(targetSeconds: real): void {
        if (!win.currentPlayer || win.trackLenSec <= 0) return;
        const clamped = Math.max(0.0, Math.min(win.trackLenSec, targetSeconds));
        if (win.currentPlayer.canSeek) {
            win.currentPlayer.position = clamped;
        } else {
            Quickshell.execDetached(["playerctl", "-p", win.currentPlayer.identity || "spotify", "position", String(clamped)]);
        }
    }

    function togglePlayPause(): void {
        if (win.currentPlayer) {
            if (win.currentPlayer.canTogglePlaying) {
                win.currentPlayer.togglePlaying();
            } else if (win.isPlaying && win.currentPlayer.canPause) {
                win.currentPlayer.pause();
            } else if (!win.isPlaying && win.currentPlayer.canPlay) {
                win.currentPlayer.play();
            } else {
                Quickshell.execDetached(["playerctl", "-p", win.currentPlayer.identity || "spotify", "play-pause"]);
            }
        } else {
            Quickshell.execDetached(["playerctl", "-p", "spotify", "play-pause"]);
        }
    }

    function nextTrack(): void {
        if (win.currentPlayer) {
            if (win.currentPlayer.canGoNext) win.currentPlayer.next();
            else Quickshell.execDetached(["playerctl", "-p", win.currentPlayer.identity || "spotify", "next"]);
        } else {
            Quickshell.execDetached(["playerctl", "-p", "spotify", "next"]);
        }
    }

    function prevTrack(): void {
        if (win.currentPlayer) {
            if (win.currentPlayer.canGoPrevious) win.currentPlayer.previous();
            else Quickshell.execDetached(["playerctl", "-p", win.currentPlayer.identity || "spotify", "previous"]);
        } else {
            Quickshell.execDetached(["playerctl", "-p", "spotify", "previous"]);
        }
    }

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
        // LEFT COLUMN (Clock/Weather + Multi-Source Media + Screen Time)
        // ==========================================
        Column {
            id: leftCol
            width: 480
            spacing: 14

            // ------------------------------------------
            // 1. CLOCK & CAELESTIA WEATHER COMPARTMENT
            // ------------------------------------------
            Card {
                id: timeCard
                width: parent.width
                height: win.showWeather ? 320 : 182
                radius: Theme.rounding.xl
                hoverable: true

                Behavior on height {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                // --- CLOCK MODE VIEW ---
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 4
                    visible: !win.showWeather

                    // Top Bar: View Tabs + Live Weather Badge
                    RowLayout {
                        Layout.fillWidth: true

                        // View mode pill: Clock / Weather
                        Row {
                            spacing: 4

                            Rectangle {
                                height: 26
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.primary, 0.20)
                                border.color: Theme.alpha(Theme.primary, 0.35)
                                border.width: 1
                                width: clockTabRow.implicitWidth + 16

                                Row {
                                    id: clockTabRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Icon {
                                        name: "schedule"
                                        size: 13
                                        color: Theme.primary
                                    }
                                    StyledText {
                                        text: "Time"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: Theme.primary
                                    }
                                }
                            }

                            Rectangle {
                                height: 26
                                radius: Theme.rounding.full
                                color: weatherTabArea.containsMouse ? Theme.alpha(Theme.surfaceVariant, 0.60) : Theme.alpha(Theme.surfaceVariant, 0.25)
                                border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                                border.width: 1
                                width: weatherTabRow.implicitWidth + 16

                                Row {
                                    id: weatherTabRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Icon {
                                        name: Weather.icon
                                        size: 13
                                        color: Theme.textSecondary
                                    }
                                    StyledText {
                                        text: "Weather"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: Theme.textSecondary
                                    }
                                }

                                MouseArea {
                                    id: weatherTabArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.showWeather = true
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Live Weather Pill (Open-Meteo & IP-API data)
                        Rectangle {
                            height: 26
                            radius: Theme.rounding.full
                            color: weatherBadgeArea.containsMouse ? Theme.alpha(Theme.primary, 0.18) : Theme.alpha(Theme.surfaceVariant, 0.35)
                            border.color: weatherBadgeArea.containsMouse ? Theme.alpha(Theme.primary, 0.40) : Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1
                            Layout.preferredWidth: weatherPillRow.implicitWidth + 18
                            scale: weatherBadgeArea.pressed ? 0.94 : (weatherBadgeArea.containsMouse ? 1.03 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                id: weatherPillRow
                                anchors.centerIn: parent
                                spacing: 5

                                Icon {
                                    name: Weather.icon
                                    size: 14
                                    color: Theme.primary
                                }

                                StyledText {
                                    text: Weather.city + " • " + Weather.temp + " " + Weather.condition
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: weatherBadgeArea.containsMouse ? Theme.text : Theme.textSecondary
                                }

                                Icon {
                                    name: "chevron_right"
                                    size: 14
                                    color: Theme.textSecondary
                                }
                            }

                            MouseArea {
                                id: weatherBadgeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.showWeather = true
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Prominent Caelestia Typography Clock
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

                // --- CAELESTIA NATIVE WEATHER VIEW ---
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10
                    visible: win.showWeather

                    // Top Bar: Back to Clock + Sunrise & Sunset
                    RowLayout {
                        Layout.fillWidth: true

                        // Return to Time Tab Pill
                        Rectangle {
                            height: 26
                            radius: Theme.rounding.full
                            color: backToTimeArea.containsMouse ? Theme.alpha(Theme.primary, 0.22) : Theme.alpha(Theme.surfaceVariant, 0.40)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.20)
                            border.width: 1
                            width: backRow.implicitWidth + 16

                            Row {
                                id: backRow
                                anchors.centerIn: parent
                                spacing: 4
                                Icon {
                                    name: "arrow_back"
                                    size: 13
                                    color: Theme.primary
                                }
                                StyledText {
                                    text: "Clock"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.text
                                }
                            }

                            MouseArea {
                                id: backToTimeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.showWeather = false
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Sunrise & Sunset Indicators
                        Row {
                            spacing: 12

                            Row {
                                spacing: 4
                                Icon {
                                    name: "wb_twilight"
                                    size: 14
                                    color: Theme.tertiary
                                }
                                StyledText {
                                    text: Weather.sunrise
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.textSecondary
                                }
                            }

                            Row {
                                spacing: 4
                                Icon {
                                    name: "bedtime"
                                    size: 14
                                    color: Theme.tertiary
                                }
                                StyledText {
                                    text: Weather.sunset
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.textSecondary
                                }
                            }
                        }
                    }

                    // Weather Hero Header Row: City + Big Temp & Icon + Condition
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: Weather.city
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: Theme.text
                            }
                            StyledText {
                                text: Qt.formatDate(win.currentTime, "dddd, MMMM d")
                                font.pixelSize: 12
                                color: Theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 12

                            Icon {
                                name: Weather.icon
                                size: 44
                                color: Theme.primaryFixed
                            }

                            ColumnLayout {
                                spacing: 0

                                Row {
                                    spacing: 4
                                    StyledText {
                                        text: Weather.temp
                                        font.pixelSize: 32
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                    }

                                    // Unit Toggle Pill (°F / °C)
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 18
                                        width: 28
                                        radius: Theme.rounding.full
                                        color: unitArea.containsMouse ? Theme.alpha(Theme.primary, 0.20) : Theme.alpha(Theme.surfaceVariant, 0.40)
                                        border.color: Theme.alpha(Theme.outlineVariant, 0.20)
                                        border.width: 1

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: Weather.useFahrenheit ? "°C" : "°F"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: Theme.textSecondary
                                        }

                                        MouseArea {
                                            id: unitArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Weather.toggleUnit()
                                        }
                                    }
                                }

                                StyledText {
                                    text: Weather.condition
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: Theme.textSecondary
                                }
                            }
                        }
                    }

                    // 3 Weather Stats Cards: Humidity | Feels Like | Wind
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Humidity Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.rounding.md
                            color: Theme.alpha(Theme.surfaceVariant, 0.40)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    name: "water_drop"
                                    size: 15
                                    color: Theme.secondary
                                }
                                StyledText {
                                    text: "Humidity " + Weather.humidity + "%"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.text
                                }
                            }
                        }

                        // Feels Like Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.rounding.md
                            color: Theme.alpha(Theme.surfaceVariant, 0.40)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    name: "thermostat"
                                    size: 15
                                    color: Theme.primary
                                }
                                StyledText {
                                    text: "Feels " + Weather.feelsLike
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.text
                                }
                            }
                        }

                        // Wind Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.rounding.md
                            color: Theme.alpha(Theme.surfaceVariant, 0.40)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    name: "air"
                                    size: 15
                                    color: Theme.tertiary
                                }
                                StyledText {
                                    text: Weather.windSpeed
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.text
                                }
                            }
                        }
                    }

                    // 7-Day Forecast Section Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: "7-DAY FORECAST"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                            color: Theme.textSecondary
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.alpha(Theme.outlineVariant, 0.15)
                        }
                    }

                    // 7-Day Forecast Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: Weather.forecast

                            Rectangle {
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                height: 74
                                radius: Theme.rounding.md
                                color: Theme.alpha(Theme.surfaceVariant, 0.35)
                                border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.day
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: index === 0 ? Theme.primary : Theme.text
                                    }

                                    Icon {
                                        Layout.alignment: Qt.AlignHCenter
                                        name: modelData.icon
                                        size: 16
                                        color: Theme.primaryFixed
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.tempRange || (modelData.minTemp + "° / " + modelData.maxTemp + "°")
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        color: Theme.textSecondary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------
            // 2. DYNAMIC MULTI-SOURCE MEDIA PLAYER
            // ------------------------------------------
            Card {
                id: musicCard
                width: parent.width
                height: 148
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // Top Bar: Player Source Badge + Source Dots + Looper & Volume Controls
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Source Identity Badge
                        Rectangle {
                            height: 24
                            radius: Theme.rounding.full
                            color: sourceBadgeArea.containsMouse ? Theme.alpha(Theme.primary, 0.18) : Theme.alpha(Theme.surfaceVariant, 0.50)
                            border.color: sourceBadgeArea.containsMouse ? Theme.alpha(Theme.primary, 0.35) : Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1
                            Layout.preferredWidth: sourceRow.implicitWidth + 14
                            scale: sourceBadgeArea.pressed ? 0.94 : (sourceBadgeArea.containsMouse ? 1.04 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                id: sourceRow
                                anchors.centerIn: parent
                                spacing: 5

                                IconImage {
                                    source: Quickshell.iconPath(win.getPlayerIcon(win.currentPlayer), "multimedia-player")
                                    implicitSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: win.getPlayerIdentity(win.currentPlayer)
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: sourceBadgeArea.containsMouse ? Theme.text : Theme.textSecondary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: sourceBadgeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (win.playerCount > 1) {
                                        win.currentPlayerIndex = (win.clampedPlayerIndex + 1) % win.playerCount;
                                    }
                                }
                            }
                        }

                        // Navigation Dots for Active Audio Sources
                        Row {
                            spacing: 5
                            Layout.alignment: Qt.AlignVCenter
                            visible: win.playerCount > 1

                            Repeater {
                                model: win.playerCount

                                Rectangle {
                                    required property int index

                                    width: index === win.clampedPlayerIndex ? 16 : 6
                                    height: 6
                                    radius: Theme.rounding.full
                                    color: index === win.clampedPlayerIndex
                                        ? Theme.primary
                                        : (dotArea.containsMouse ? Theme.text : Theme.alpha(Theme.textSecondary, 0.35))

                                    Behavior on width { NumberAnimation { duration: 150 } }
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    MouseArea {
                                        id: dotArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.currentPlayerIndex = index
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Looper: Shuffle Toggle
                        Rectangle {
                            width: 28
                            height: 28
                            radius: Theme.rounding.full
                            color: win.isShuffle
                                ? Theme.alpha(Theme.primary, 0.22)
                                : (shuffArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.70) : "transparent")
                            border.color: win.isShuffle ? Theme.alpha(Theme.primary, 0.40) : "transparent"
                            border.width: 1
                            scale: shuffArea.pressed ? 0.90 : (shuffArea.containsMouse ? 1.06 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Icon {
                                anchors.centerIn: parent
                                name: "shuffle"
                                size: 15
                                color: win.isShuffle ? Theme.primary : Theme.textSecondary
                            }

                            MouseArea {
                                id: shuffArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (win.currentPlayer) {
                                        win.currentPlayer.shuffle = !win.currentPlayer.shuffle;
                                    }
                                }
                            }
                        }

                        // Looper: Repeat Mode (None / Track / Playlist)
                        Rectangle {
                            width: 28
                            height: 28
                            radius: Theme.rounding.full
                            color: win.loopState > 0
                                ? Theme.alpha(Theme.primary, 0.22)
                                : (repArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.70) : "transparent")
                            border.color: win.loopState > 0 ? Theme.alpha(Theme.primary, 0.40) : "transparent"
                            border.width: 1
                            scale: repArea.pressed ? 0.90 : (repArea.containsMouse ? 1.06 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Icon {
                                anchors.centerIn: parent
                                name: win.loopState === 1 ? "repeat_one" : "repeat"
                                size: 15
                                color: win.loopState > 0 ? Theme.primary : Theme.textSecondary
                            }

                            MouseArea {
                                id: repArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (win.currentPlayer) {
                                        win.currentPlayer.loopState = (win.currentPlayer.loopState + 1) % 3;
                                    }
                                }
                            }
                        }

                        // Volume Control for Active Source
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: (win.playerVolume <= 0.01) ? "volume_off" : (win.playerVolume < 0.5 ? "volume_down" : "volume_up")
                                size: 16
                                color: volArea.containsMouse ? Theme.primary : Theme.textSecondary

                                MouseArea {
                                    id: volArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!win.currentPlayer) return;
                                        if (win.playerVolume > 0.01) {
                                            win.lastNonZeroVolume = win.playerVolume;
                                            win.currentPlayer.volume = 0.0;
                                        } else {
                                            win.currentPlayer.volume = win.lastNonZeroVolume || 1.0;
                                        }
                                    }
                                }
                            }

                            // Volume Slider Bar
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 48
                                height: 4
                                radius: Theme.rounding.full
                                color: Theme.alpha(Theme.secondaryContainer, 0.45)

                                Rectangle {
                                    width: parent.width * Math.min(1.0, Math.max(0.0, win.playerVolume))
                                    height: parent.height
                                    radius: Theme.rounding.full
                                    color: Theme.primary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onWheel: (wheel) => {
                                        if (win.currentPlayer) {
                                            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                            win.currentPlayer.volume = Math.max(0.0, Math.min(1.0, win.playerVolume + delta));
                                        }
                                    }
                                    onClicked: (mouse) => {
                                        if (win.currentPlayer) {
                                            win.currentPlayer.volume = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        }
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (pressed && win.currentPlayer) {
                                            win.currentPlayer.volume = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        }
                                    }
                                }
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(win.playerVolume * 100) + "%"
                                font.pixelSize: 10
                                font.family: Theme.fonts.familyMono
                                color: Theme.textSecondary
                            }
                        }
                    }

                    // Middle Row: Album Artwork + Metadata + Playback Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Album Artwork Container
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
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
                                size: 24
                                color: Theme.primary
                            }
                        }

                        // Track Title & Artist Metadata
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: win.trackTitle
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: win.trackArtist
                                font.pixelSize: 11
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Playback Controls [<-] [play/pause] [->]
                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            // Previous Track Button
                            Rectangle {
                                width: 32
                                height: 32
                                radius: Theme.rounding.full
                                color: prevArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.90) : Theme.alpha(Theme.surfaceContainerHigh, 0.55)
                                scale: prevArea.pressed ? 0.92 : (prevArea.containsMouse ? 1.06 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip_previous"
                                    size: 17
                                    color: Theme.text
                                }

                                MouseArea {
                                    id: prevArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.prevTrack()
                                }
                            }

                            // Play/Pause Accent Pill Button (Caelestia Stadium Morph)
                            Rectangle {
                                width: 50
                                height: 32
                                radius: Theme.rounding.full
                                color: Theme.primary
                                scale: playArea.pressed ? 0.92 : (playArea.containsMouse ? 1.05 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 120 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: win.isPlaying ? "pause" : "play_arrow"
                                    size: 18
                                    color: Theme.textOnPrimary
                                }

                                MouseArea {
                                    id: playArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.togglePlayPause()
                                }
                            }

                            // Next Track Button
                            Rectangle {
                                width: 32
                                height: 32
                                radius: Theme.rounding.full
                                color: nextArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.90) : Theme.alpha(Theme.surfaceContainerHigh, 0.55)
                                scale: nextArea.pressed ? 0.92 : (nextArea.containsMouse ? 1.06 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip_next"
                                    size: 17
                                    color: Theme.text
                                }

                                MouseArea {
                                    id: nextArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.nextTrack()
                                }
                            }
                        }
                    }

                    // Progress Track with Technical Timers & Full Seek Support (Click & Drag)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: win.formatTime(win.isDraggingSeek ? win.dragSeekPos : win.trackPosSec)
                            font.pixelSize: 10
                            font.family: Theme.fonts.familyMono
                            color: Theme.textSecondary
                        }

                        Rectangle {
                            id: progTrack
                            Layout.fillWidth: true
                            height: 6
                            radius: Theme.rounding.full
                            color: Theme.alpha(Theme.secondaryContainer, 0.45)

                            Rectangle {
                                width: parent.width * win.displayProgress
                                height: parent.height
                                radius: Theme.rounding.full
                                color: Theme.primary

                                Behavior on width {
                                    enabled: !win.isDraggingSeek
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true

                                onPressed: (mouse) => {
                                    if (win.trackLenSec > 0) {
                                        win.isDraggingSeek = true;
                                        const pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        win.dragSeekPos = pct * win.trackLenSec;
                                    }
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed && win.trackLenSec > 0) {
                                        const pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        win.dragSeekPos = pct * win.trackLenSec;
                                    }
                                }
                                onReleased: (mouse) => {
                                    if (win.isDraggingSeek) {
                                        win.isDraggingSeek = false;
                                        const pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        win.seekTo(pct * win.trackLenSec);
                                    }
                                }
                                onClicked: (mouse) => {
                                    if (win.trackLenSec > 0) {
                                        const pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        win.seekTo(pct * win.trackLenSec);
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
                height: 262
                radius: Theme.rounding.xl
                hoverable: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

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
                            height: 24
                            radius: Theme.rounding.full
                            color: Theme.alpha(Theme.surfaceVariant, 0.45)
                            border.color: Theme.alpha(Theme.outlineVariant, 0.15)
                            border.width: 1
                            Layout.preferredWidth: stTotalText.implicitWidth + 16

                            StyledText {
                                id: stTotalText
                                anchors.centerIn: parent
                                text: (win.screenTimeView === 0 ? ScreenTime.todayTotalFormatted : ScreenTime.weekTotalFormatted) || "0m"
                                font.pixelSize: 11
                                font.family: Theme.fonts.familySans
                                font.weight: Font.DemiBold
                                color: Theme.primary
                            }
                        }
                    }

                    // Application Usage Rows (Real data from ScreenTime service)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        Repeater {
                            model: win.screenTimeView === 0 ? ScreenTime.todayList : ScreenTime.weekList

                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true

                                    IconImage {
                                        source: modelData && modelData.icon ? Quickshell.iconPath(modelData.icon, modelData.fallback) : ""
                                        implicitSize: 16
                                    }

                                    StyledText {
                                        text: modelData && modelData.name ? modelData.name : ""
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Theme.text
                                    }

                                    Item { Layout.fillWidth: true }

                                    StyledText {
                                        text: modelData && modelData.time ? (modelData.time + " (" + Math.round((modelData.pct || 0) * 100) + "%)") : ""
                                        font.pixelSize: 11
                                        font.family: Theme.fonts.familySans
                                        font.weight: Font.Medium
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
            // Height spans left column exact height: 182 + 14 + 148 + 14 + 262 = 620px
            height: 620
            radius: Theme.rounding.xl
            hoverable: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // Header Bar: Clean & Native (Square dots icon removed per user request)
                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: "Applications"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.text
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

                // 4x3 Icon-First Grid (Real User Applications with Verified Icons)
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: [
                            { name: "Brave", icon: "brave-desktop", fallback: "web-browser", exec: "brave" },
                            { name: "Chromium", icon: "chromium", fallback: "web-browser", exec: "chromium" },
                            { name: "VS Code", icon: "vscode", fallback: "text-editor", exec: "code" },
                            { name: "Kitty", icon: "kitty", fallback: "utilities-terminal", exec: "kitty" },
                            { name: "Spotify", icon: "spotify-client", fallback: "audio-player", exec: "spotify" },
                            { name: "Discord", icon: "omarchy-discord", fallback: "chat", exec: "omarchy-launch-webapp https://discord.com/channels/@me" },
                            { name: "Steam", icon: "steam", fallback: "applications-games", exec: "steam" },
                            { name: "Obsidian", icon: "obsidian", fallback: "text-editor", exec: "obsidian" },
                            { name: "Files", icon: "org.xfce.thunar", fallback: "system-file-manager", exec: "thunar" },
                            { name: "OBS Studio", icon: "com.obsproject.Studio", fallback: "video-display", exec: "obs" },
                            { name: "Antigravity", icon: "/home/erebusstride/.local/bin/Antigravity/Google-Antigravity-Icon-White.png", fallback: "utilities-terminal", exec: "/home/erebusstride/.local/bin/Antigravity/antigravity" },
                            { name: "Aether", icon: "aether", fallback: "application-x-executable", exec: "aether" }
                        ]

                        AppIconTile {
                            required property var modelData
                            name: modelData.name
                            icon: modelData.icon
                            fallback: modelData.fallback
                            execCmd: modelData.exec
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
