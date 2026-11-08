pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
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
        layoutLoader.running = true;
    }

    Connections {
        target: Theme
        function onSchemeNameChanged(): void {
            Quickshell.execDetached(["hyprctl", "--batch", "eval hl.layer_rule({ match = { namespace = '^caelestia-desktop-widgets$' }, blur = true, ignore_alpha = 0.15 })"]);
        }
    }

    // --- Dynamic Input Masking (Click-Through) ---
    // Tracks the independent floating coordinates of each widget
    mask: Region {
        Region { item: timeCard }
        Region { item: musicCard }
        Region { item: screenTimeCard }
        Region { item: appDrawerCard }
    }

    // PipeWire node tracker for real audio stream volume control
    PwObjectTracker {
        objects: Pipewire.nodes ? Pipewire.nodes.values : []
    }

    // Live clock ticker
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }
    property var currentTime: new Date()

    // Weather expansion toggle
    property bool showWeather: false

    // ==========================================
    // PERSISTENT DESKTOP LAYOUT (Position & Size)
    // ==========================================
    readonly property string layoutPath: Quickshell.env("HOME") + "/.local/state/caelestia-widgets/layout.json"

    function saveLayout(): void {
        const data = {
            clock: { x: Math.round(timeCard.x), y: Math.round(timeCard.y), w: Math.round(timeCard.width), h: Math.round(timeCard.height) },
            music: { x: Math.round(musicCard.x), y: Math.round(musicCard.y), w: Math.round(musicCard.width), h: Math.round(musicCard.height) },
            screentime: { x: Math.round(screenTimeCard.x), y: Math.round(screenTimeCard.y), w: Math.round(screenTimeCard.width), h: Math.round(screenTimeCard.height) },
            apps: { x: Math.round(appDrawerCard.x), y: Math.round(appDrawerCard.y), w: Math.round(appDrawerCard.width), h: Math.round(appDrawerCard.height) }
        };
        const jsonStr = JSON.stringify(data);
        Quickshell.execDetached(["python3", "-c", 
            "import sys, os\n" +
            "path = sys.argv[1]\n" +
            "os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
            "with open(path + '.tmp', 'w') as f:\n" +
            "    f.write(sys.argv[2])\n" +
            "os.replace(path + '.tmp', path)\n",
            win.layoutPath, jsonStr
        ]);
    }

    Process {
        id: layoutLoader
        command: ["python3", "-c",
            "import sys, os\n" +
            "path = sys.argv[1]\n" +
            "if os.path.exists(path):\n" +
            "    with open(path) as f: print(f.read())\n" +
            "else: print('')\n",
            win.layoutPath
        ]
        running: false
        stdout: StdioCollector {
            id: layoutCollector
            onStreamFinished: {
                win.applySavedLayout(layoutCollector.text);
            }
        }
    }

    function applySavedLayout(text: string): void {
        const trimmed = (text || "").trim();
        if (trimmed.length > 0) {
            try {
                const data = JSON.parse(trimmed);
                const clock = data.clock || data.time;
                const music = data.music || data.media;
                const screentime = data.screentime;
                const apps = data.apps;

                if (clock && clock.x !== undefined && clock.y !== undefined) {
                    timeCard.x = Number(clock.x);
                    timeCard.y = Number(clock.y);
                    const w = clock.w !== undefined ? clock.w : clock.width;
                    const h = clock.h !== undefined ? clock.h : clock.height;
                    if (w !== undefined && !isNaN(w)) timeCard.width = Math.max(timeCard.minWidth, Math.min(timeCard.maxWidth, Number(w)));
                    if (h !== undefined && !isNaN(h)) timeCard.height = Math.max(timeCard.minHeight, Math.min(timeCard.maxHeight, Number(h)));
                }
                if (music && music.x !== undefined && music.y !== undefined) {
                    musicCard.x = Number(music.x);
                    musicCard.y = Number(music.y);
                    const w = music.w !== undefined ? music.w : music.width;
                    const h = music.h !== undefined ? music.h : music.height;
                    if (w !== undefined && !isNaN(w)) musicCard.width = Math.max(musicCard.minWidth, Math.min(musicCard.maxWidth, Number(w)));
                    if (h !== undefined && !isNaN(h)) musicCard.height = Math.max(musicCard.minHeight, Math.min(musicCard.maxHeight, Number(h)));
                }
                if (screentime && screentime.x !== undefined && screentime.y !== undefined) {
                    screenTimeCard.x = Number(screentime.x);
                    screenTimeCard.y = Number(screentime.y);
                    const w = screentime.w !== undefined ? screentime.w : screentime.width;
                    const h = screentime.h !== undefined ? screentime.h : screentime.height;
                    if (w !== undefined && !isNaN(w)) screenTimeCard.width = Math.max(screenTimeCard.minWidth, Math.min(screenTimeCard.maxWidth, Number(w)));
                    if (h !== undefined && !isNaN(h)) screenTimeCard.height = Math.max(screenTimeCard.minHeight, Math.min(screenTimeCard.maxHeight, Number(h)));
                }
                if (apps && apps.x !== undefined && apps.y !== undefined) {
                    appDrawerCard.x = Number(apps.x);
                    appDrawerCard.y = Number(apps.y);
                    const w = apps.w !== undefined ? apps.w : apps.width;
                    const h = apps.h !== undefined ? apps.h : apps.height;
                    if (w !== undefined && !isNaN(w)) appDrawerCard.width = Math.max(appDrawerCard.minWidth, Math.min(appDrawerCard.maxWidth, Number(w)));
                    if (h !== undefined && !isNaN(h)) appDrawerCard.height = Math.max(appDrawerCard.minHeight, Math.min(appDrawerCard.maxHeight, Number(h)));
                }
                return;
            } catch (e) {
                console.warn("[Layout] Failed to parse layout JSON:", e);
            }
        }
        initDefaultLayout();
    }

    function initDefaultLayout(): void {
        const screenW = win.width > 0 ? win.width : 1920;
        const screenH = win.height > 0 ? win.height : 1080;
        const totalW = 440 + 20 + 480;
        const totalH = 580;
        const startX = Math.round((screenW - totalW) / 2);
        const startY = Math.round((screenH - totalH) / 2);

        timeCard.x = startX;
        timeCard.y = startY;
        timeCard.width = 440;
        timeCard.height = 148;

        musicCard.x = startX;
        musicCard.y = startY + 148 + 14;
        musicCard.width = 440;
        musicCard.height = 156;

        screenTimeCard.x = startX;
        screenTimeCard.y = startY + 148 + 14 + 156 + 14;
        screenTimeCard.width = 440;
        screenTimeCard.height = 248;

        appDrawerCard.x = startX + 440 + 20;
        appDrawerCard.y = startY;
        appDrawerCard.width = 480;
        appDrawerCard.height = 580;
    }

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

    function playerctlName(player): string {
        if (!player) return "";
        if (player.dbusName) {
            return String(player.dbusName).replace("org.mpris.MediaPlayer2.", "");
        }
        if (player.identity) {
            return String(player.identity).toLowerCase();
        }
        return "";
    }

    function getPlayerStream(player) {
        if (!player || !Pipewire.nodes) return null;
        const pName = (player.identity || "").toLowerCase();
        const pEntry = (player.desktopEntry || "").toLowerCase();
        const dbus = (player.dbusName || "").toLowerCase();

        for (let i = 0; i < Pipewire.nodes.values.length; ++i) {
            const n = Pipewire.nodes.values[i];
            if (n && n.isStream && n.audio) {
                const appName = (n.properties["application.name"] || "").toLowerCase();
                const appBin = (n.properties["application.process.binary"] || "").toLowerCase();
                const nodeName = (n.name || "").toLowerCase();

                if (pName && (appName.includes(pName) || appBin.includes(pName) || nodeName.includes(pName))) return n;
                if (pEntry && (appName.includes(pEntry) || appBin.includes(pEntry) || nodeName.includes(pEntry))) return n;
                if (dbus.includes("chromium") && (appName.includes("chromium") || appBin.includes("chromium") || nodeName.includes("chromium"))) return n;
                if (dbus.includes("brave") && (appName.includes("brave") || appBin.includes("brave") || nodeName.includes("brave"))) return n;
                if (dbus.includes("spotify") && (appName.includes("spotify") || appBin.includes("spotify") || nodeName.includes("spotify"))) return n;
                if (dbus.includes("firefox") && (appName.includes("firefox") || appBin.includes("firefox") || nodeName.includes("firefox"))) return n;
            }
        }
        return null;
    }

    readonly property real playerVolume: {
        const s = getPlayerStream(currentPlayer);
        if (s && s.audio) {
            return s.audio.muted ? 0.0 : s.audio.volume;
        }
        if (currentPlayer && currentPlayer.volume !== undefined) {
            return currentPlayer.volume;
        }
        return 1.0;
    }

    property real lastNonZeroVolume: 1.0

    function setPlayerVolume(val: real): void {
        const clamped = Math.max(0.0, Math.min(1.0, val));
        const s = getPlayerStream(currentPlayer);
        if (s && s.audio) {
            s.audio.muted = (clamped <= 0.001);
            s.audio.volume = clamped;
        }
        if (currentPlayer && currentPlayer.volumeSupported) {
            currentPlayer.volume = clamped;
        }
        if (currentPlayer) {
            const pid = playerctlName(currentPlayer);
            if (pid) Quickshell.execDetached(["playerctl", "-p", pid, "volume", String(clamped)]);
        }
    }

    function togglePlayerMute(): void {
        if (!currentPlayer) return;
        const s = getPlayerStream(currentPlayer);
        if (s && s.audio) {
            s.audio.muted = !s.audio.muted;
            return;
        }
        if (playerVolume > 0.01) {
            lastNonZeroVolume = playerVolume;
            setPlayerVolume(0.0);
        } else {
            setPlayerVolume(lastNonZeroVolume || 1.0);
        }
    }

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
        }
        const pid = win.playerctlName(win.currentPlayer);
        if (pid) {
            Quickshell.execDetached(["playerctl", "-p", pid, "position", String(clamped)]);
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
                const pid = win.playerctlName(win.currentPlayer);
                if (pid) Quickshell.execDetached(["playerctl", "-p", pid, "play-pause"]);
                else Quickshell.execDetached(["playerctl", "play-pause"]);
            }
        } else {
            Quickshell.execDetached(["playerctl", "play-pause"]);
        }
    }

    function nextTrack(): void {
        if (win.currentPlayer) {
            if (win.currentPlayer.canGoNext) {
                win.currentPlayer.next();
            } else {
                if (win.currentPlayer.canSeek) {
                    win.currentPlayer.seek(10.0);
                } else {
                    const pid = win.playerctlName(win.currentPlayer);
                    if (pid) Quickshell.execDetached(["playerctl", "-p", pid, "next"]);
                    else Quickshell.execDetached(["playerctl", "next"]);
                }
            }
        } else {
            Quickshell.execDetached(["playerctl", "next"]);
        }
    }

    function prevTrack(): void {
        if (win.currentPlayer) {
            if (win.currentPlayer.canGoPrevious) {
                win.currentPlayer.previous();
            } else {
                if (win.currentPlayer.canSeek) {
                    if (win.currentPlayer.position > 10.0) {
                        win.currentPlayer.seek(-10.0);
                    } else {
                        win.currentPlayer.position = 0.0;
                    }
                } else {
                    const pid = win.playerctlName(win.currentPlayer);
                    if (pid) Quickshell.execDetached(["playerctl", "-p", pid, "previous"]);
                    else Quickshell.execDetached(["playerctl", "previous"]);
                }
            }
        } else {
            Quickshell.execDetached(["playerctl", "previous"]);
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
    // 1. CLOCK & CAELESTIA WEATHER WIDGET
    // ==========================================
    ResizableCard {
        id: timeCard
        widgetId: "clock"
        x: 490
        y: 262
        width: 440
        height: 148
        minWidth: 320
        maxWidth: 850
        minHeight: win.showWeather ? 260 : 120
        maxHeight: 550
        hoverable: true
        onGeometryChangedByUser: win.saveLayout()

        // --- CLOCK MODE VIEW ---
        Item {
            anchors.fill: parent
            anchors.margins: 20
            visible: !win.showWeather

            // Weather pill button (top right)
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                height: 28
                radius: Theme.rounding.full
                color: weatherPillArea.containsMouse ? Theme.alpha(Theme.primary, 0.20) : Theme.alpha(Theme.surfaceVariant, 0.40)
                border.color: weatherPillArea.containsMouse ? Theme.alpha(Theme.primary, 0.35) : Theme.alpha(Theme.outlineVariant, 0.15)
                border.width: 1
                width: weatherPillRow.implicitWidth + 18
                scale: weatherPillArea.pressed ? 0.95 : (weatherPillArea.containsMouse ? 1.03 : 1.0)

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 120 } }

                Row {
                    id: weatherPillRow
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        name: Weather.icon
                        size: 15
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: Weather.temp + " • " + Weather.condition
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: weatherPillArea.containsMouse ? Theme.text : Theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: weatherPillArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.showWeather = true
                }
            }

            // Main Clock and Date Row
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 12
                spacing: 20

                // Clock numbers
                Row {
                    spacing: 2
                    Layout.alignment: Qt.AlignBottom

                    StyledText {
                        text: Qt.formatTime(win.currentTime, "hh")
                        font.pixelSize: 64
                        font.weight: Font.Bold
                        font.family: Theme.fonts.family
                        font.features: ({ "tnum": 1 })
                        color: Theme.primary
                    }

                    StyledText {
                        text: ":"
                        font.pixelSize: 58
                        font.weight: Font.DemiBold
                        font.family: Theme.fonts.family
                        font.features: ({ "tnum": 1 })
                        color: Theme.primaryFixed
                        opacity: 0.85
                    }

                    StyledText {
                        text: Qt.formatTime(win.currentTime, "mm")
                        font.pixelSize: 64
                        font.weight: Font.Bold
                        font.family: Theme.fonts.family
                        font.features: ({ "tnum": 1 })
                        color: Theme.text
                    }
                }

                // Date column
                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    StyledText {
                        text: Qt.formatDateTime(win.currentTime, "dddd")
                        font.pixelSize: 19
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }

                    StyledText {
                        text: Qt.formatDateTime(win.currentTime, "d MMMM yyyy")
                        font.pixelSize: 12
                        font.weight: Font.Normal
                        color: Theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // --- WEATHER FORECAST VIEW ---
        Flickable {
            anchors.fill: parent
            anchors.margins: 18
            contentHeight: weatherContentCol.implicitHeight
            contentWidth: width
            clip: true
            visible: win.showWeather

            ColumnLayout {
                id: weatherContentCol
                width: parent.width
                spacing: 12

                // Header Bar: Back to Clock + Sunrise/Sunset
                RowLayout {
                    Layout.fillWidth: true

                    Rectangle {
                        height: 26
                        radius: Theme.rounding.full
                        color: backTimeArea.containsMouse ? Theme.alpha(Theme.primary, 0.22) : Theme.alpha(Theme.surfaceVariant, 0.40)
                        border.color: Theme.alpha(Theme.outlineVariant, 0.20)
                        border.width: 1
                        width: backRow.implicitWidth + 16

                        Row {
                            id: backRow
                            anchors.centerIn: parent
                            spacing: 4
                            Icon {
                                name: "arrow_back"
                                size: 14
                                color: Theme.primary
                            }
                            StyledText {
                                text: "Clock"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.text
                            }
                        }

                        MouseArea {
                            id: backTimeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.showWeather = false
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 12
                        Row {
                            spacing: 4
                            Icon { name: "wb_twilight"; size: 14; color: Theme.tertiary }
                            StyledText { text: Weather.sunrise; font.pixelSize: 11; color: Theme.textSecondary }
                        }
                        Row {
                            spacing: 4
                            Icon { name: "bedtime"; size: 14; color: Theme.tertiary }
                            StyledText { text: Weather.sunset; font.pixelSize: 11; color: Theme.textSecondary }
                        }
                    }
                }

                // Main Weather Info: City + Temp + Condition
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: Weather.city
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: Theme.text
                        }
                        StyledText {
                            text: Qt.formatDate(win.currentTime, "dddd, MMMM d")
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 10
                        Icon {
                            name: Weather.icon
                            size: 38
                            color: Theme.primaryFixed
                        }
                        ColumnLayout {
                            spacing: 0
                            Row {
                                spacing: 4
                                StyledText {
                                    text: Weather.temp
                                    font.pixelSize: 28
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 18
                                    width: 28
                                    radius: Theme.rounding.full
                                    color: unitToggleArea.containsMouse ? Theme.alpha(Theme.primary, 0.20) : Theme.alpha(Theme.surfaceVariant, 0.40)
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
                                        id: unitToggleArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Weather.toggleUnit()
                                    }
                                }
                            }
                            StyledText {
                                text: Weather.condition
                                font.pixelSize: 11
                                color: Theme.textSecondary
                            }
                        }
                    }
                }

                // 3 Details Cards
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Theme.rounding.md
                        color: Theme.alpha(Theme.surfaceVariant, 0.35)
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Icon { name: "water_drop"; size: 14; color: Theme.secondary }
                            StyledText { text: Weather.humidity; font.pixelSize: 11; color: Theme.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Theme.rounding.md
                        color: Theme.alpha(Theme.surfaceVariant, 0.35)
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Icon { name: "thermostat"; size: 14; color: Theme.primary }
                            StyledText { text: Weather.feelsLike; font.pixelSize: 11; color: Theme.text }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Theme.rounding.md
                        color: Theme.alpha(Theme.surfaceVariant, 0.35)
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Icon { name: "air"; size: 14; color: Theme.tertiary }
                            StyledText { text: Weather.windSpeed; font.pixelSize: 11; color: Theme.text }
                        }
                    }
                }

                // 7-Day Forecast Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: Weather.forecastDays

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: Theme.rounding.md
                            color: Theme.alpha(Theme.surfaceVariant, 0.30)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                StyledText {
                                    text: modelData.day
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: Theme.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Icon {
                                    name: modelData.icon
                                    size: 18
                                    color: Theme.primary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                StyledText {
                                    text: modelData.maxTemp + "°"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: Theme.text
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. DYNAMIC MULTI-SOURCE MEDIA PLAYER
    // ==========================================
    ResizableCard {
        id: musicCard
        widgetId: "music"
        x: 490
        y: 426
        width: 440
        height: 156
        minWidth: 320
        maxWidth: 850
        minHeight: 120
        maxHeight: 420
        hoverable: true
        onGeometryChangedByUser: win.saveLayout()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // Top Bar: Player Source Badge + Navigation Dots + Volume Slider
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Source Identity Chip (clickable to switch)
                Rectangle {
                    height: 24
                    radius: Theme.rounding.full
                    color: sourceBadgeArea.containsMouse ? Theme.alpha(Theme.primary, 0.18) : Theme.alpha(Theme.surfaceVariant, 0.45)
                    border.color: sourceBadgeArea.containsMouse ? Theme.alpha(Theme.primary, 0.35) : Theme.alpha(Theme.outlineVariant, 0.15)
                    border.width: 1
                    Layout.preferredWidth: sourceRow.implicitWidth + 14
                    scale: sourceBadgeArea.pressed ? 0.95 : 1.0

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
                            font.weight: Font.Medium
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

                // Dots for multiple active audio sources
                Row {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    visible: win.playerCount > 1

                    Repeater {
                        model: win.playerCount
                        Rectangle {
                            required property int index
                            width: index === win.clampedPlayerIndex ? 14 : 5
                            height: 5
                            radius: Theme.rounding.full
                            color: index === win.clampedPlayerIndex ? Theme.primary : Theme.alpha(Theme.textSecondary, 0.35)
                            Behavior on width { NumberAnimation { duration: 150 } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.currentPlayerIndex = index
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Volume Slider
                Row {
                    spacing: 5
                    Layout.alignment: Qt.AlignVCenter

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: (win.playerVolume <= 0.01) ? "volume_off" : (win.playerVolume < 0.5 ? "volume_down" : "volume_up")
                        size: 16
                        color: volIconArea.containsMouse ? Theme.primary : Theme.textSecondary

                        MouseArea {
                            id: volIconArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.togglePlayerMute()
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 52
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
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            onWheel: (wheel) => {
                                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                win.setPlayerVolume(win.playerVolume + delta);
                            }
                            onClicked: (mouse) => win.setPlayerVolume(mouse.x / width)
                            onPositionChanged: (mouse) => {
                                if (pressed) win.setPlayerVolume(mouse.x / width);
                            }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(win.playerVolume * 100) + "%"
                        font.pixelSize: 10
                        font.features: ({ "tnum": 1 })
                        color: Theme.textSecondary
                    }
                }
            }

            // Middle Row: Album Artwork + Details + Playback Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Cover Art
                Rectangle {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 54
                    radius: 14
                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.60)
                    border.color: Theme.alpha(Theme.outlineVariant, 0.20)
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: win.trackArtUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: win.trackArtUrl !== ""
                        asynchronous: true
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "music_note"
                        size: 24
                        color: Theme.primaryFixed
                        visible: win.trackArtUrl === ""
                    }
                }

                // Track Title & Artist
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

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
                        font.weight: Font.Normal
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Controls Row
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    // Shuffle Button
                    Rectangle {
                        width: 28; height: 28
                        radius: Theme.rounding.full
                        color: win.isShuffle ? Theme.alpha(Theme.primary, 0.20) : "transparent"
                        Icon {
                            anchors.centerIn: parent
                            name: "shuffle"
                            size: 15
                            color: win.isShuffle ? Theme.primary : Theme.textSecondary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (win.currentPlayer) win.currentPlayer.shuffle = !win.currentPlayer.shuffle;
                            }
                        }
                    }

                    // Previous Track Button
                    Rectangle {
                        width: 32; height: 32
                        radius: Theme.rounding.full
                        color: prevArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.85) : Theme.alpha(Theme.surfaceContainerHigh, 0.40)
                        scale: prevArea.pressed ? 0.92 : 1.0
                        Icon { anchors.centerIn: parent; name: "skip_previous"; size: 17; color: Theme.text }
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.prevTrack()
                        }
                    }

                    // Large Play/Pause FAB Button
                    Rectangle {
                        width: 40; height: 40
                        radius: Theme.rounding.full
                        color: Theme.primary
                        scale: playFabArea.pressed ? 0.92 : (playFabArea.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120 } }

                        Icon {
                            anchors.centerIn: parent
                            name: win.isPlaying ? "pause" : "play_arrow"
                            size: 22
                            color: Theme.onPrimary
                        }

                        MouseArea {
                            id: playFabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.togglePlayPause()
                        }
                    }

                    // Next Track Button
                    Rectangle {
                        width: 32; height: 32
                        radius: Theme.rounding.full
                        color: nextArea.containsMouse ? Theme.alpha(Theme.surfaceContainerHigh, 0.85) : Theme.alpha(Theme.surfaceContainerHigh, 0.40)
                        scale: nextArea.pressed ? 0.92 : 1.0
                        Icon { anchors.centerIn: parent; name: "skip_next"; size: 17; color: Theme.text }
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.nextTrack()
                        }
                    }

                    // Repeat Button
                    Rectangle {
                        width: 28; height: 28
                        radius: Theme.rounding.full
                        color: win.loopState > 0 ? Theme.alpha(Theme.primary, 0.20) : "transparent"
                        Icon {
                            anchors.centerIn: parent
                            name: win.loopState === 1 ? "repeat_one" : "repeat"
                            size: 15
                            color: win.loopState > 0 ? Theme.primary : Theme.textSecondary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (win.currentPlayer) win.currentPlayer.loopState = (win.currentPlayer.loopState + 1) % 3;
                            }
                        }
                    }
                }
            }

            // Bottom Row: Seek Slider with Timestamps
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: win.formatTime(win.isDraggingSeek ? win.dragSeekPos : win.trackPosSec)
                    font.pixelSize: 10
                    font.features: ({ "tnum": 1 })
                    color: Theme.textSecondary
                }

                Rectangle {
                    id: progTrack
                    Layout.fillWidth: true
                    height: 5
                    radius: Theme.rounding.full
                    color: Theme.alpha(Theme.secondaryContainer, 0.45)

                    Rectangle {
                        width: parent.width * win.displayProgress
                        height: parent.height
                        radius: Theme.rounding.full
                        color: Theme.primary

                        Behavior on width {
                            enabled: !win.isDraggingSeek
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
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
                    font.features: ({ "tnum": 1 })
                    color: Theme.textSecondary
                }
            }
        }
    }

    // ==========================================
    // 3. SCREEN TIME WIDGET
    // ==========================================
    ResizableCard {
        id: screenTimeCard
        widgetId: "screentime"
        x: 490
        y: 598
        width: 440
        height: 248
        minWidth: 320
        maxWidth: 850
        minHeight: 160
        maxHeight: 550
        hoverable: true
        onGeometryChangedByUser: win.saveLayout()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header Row: Title + Total Badge + Daily/Weekly Switch
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                StyledText {
                    text: "Screen Time"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Theme.text
                }

                Rectangle {
                    height: 22
                    radius: Theme.rounding.full
                    color: Theme.alpha(Theme.primary, 0.15)
                    Layout.preferredWidth: stTotalText.implicitWidth + 14

                    StyledText {
                        id: stTotalText
                        anchors.centerIn: parent
                        text: (win.screenTimeView === 0 ? ScreenTime.todayTotalFormatted : ScreenTime.weekTotalFormatted) || "0m"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.primary
                    }
                }

                Item { Layout.fillWidth: true }

                SegmentedSwitch {
                    currentIndex: win.screenTimeView
                    onSelectionChanged: function(idx) { win.screenTimeView = idx; }
                }
            }

            // Application Usage Rows (ListModel with in-place updates)
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: stContentCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: stContentCol
                    width: parent.width
                    spacing: 8

                    StyledText {
                        visible: (win.screenTimeView === 0 ? ScreenTime.todayModel.count : ScreenTime.weekModel.count) === 0
                        text: "No active application usage recorded yet"
                        font.pixelSize: 12
                        color: Theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 15
                        Layout.bottomMargin: 15
                    }

                    Repeater {
                        model: win.screenTimeView === 0 ? ScreenTime.todayModel : ScreenTime.weekModel

                        ColumnLayout {
                            required property var model
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true

                                IconImage {
                                    source: model.icon ? (model.icon.startsWith("/") ? ("file://" + model.icon) : Quickshell.iconPath(model.icon, model.fallback)) : ""
                                    implicitSize: 16
                                }

                                StyledText {
                                    text: model.name || ""
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: Theme.text
                                }

                                Item { Layout.fillWidth: true }

                                StyledText {
                                    text: model.time ? (model.time + " (" + Math.round((model.pct || 0) * 100) + "%)") : ""
                                    font.pixelSize: 11
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
                                    width: parent.width * Math.max(0.0, Math.min(1.0, model.pct || 0))
                                    height: parent.height
                                    radius: Theme.rounding.full
                                    color: model.color || Theme.secondary

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
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ==========================================
    // 4. RESPONSIVE APPLICATION DRAWER WIDGET
    // ==========================================
    ResizableCard {
        id: appDrawerCard
        widgetId: "apps"
        x: 950
        y: 262
        width: 480
        height: 580
        minWidth: 260
        maxWidth: 1050
        minHeight: 250
        maxHeight: 900
        hoverable: true
        onGeometryChangedByUser: win.saveLayout()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header Bar
            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: "Applications"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Theme.text
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 22
                    radius: Theme.rounding.full
                    color: Theme.alpha(Theme.surfaceVariant, 0.40)
                    Layout.preferredWidth: appCountText.implicitWidth + 14

                    StyledText {
                        id: appCountText
                        anchors.centerIn: parent
                        text: "12 apps"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.textSecondary
                    }
                }
            }

            // Smooth Scrollable, Dynamically Responsive Grid
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: appGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                GridLayout {
                    id: appGrid
                    width: parent.width
                    // Responsive column calculation based on drawer width
                    columns: Math.max(2, Math.floor((width - 16) / 105))
                    rowSpacing: 10
                    columnSpacing: 10

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
                            iconSize: 46
                        }
                    }
                }
            }
        }
    }
}
