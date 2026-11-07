pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "components"

PanelWindow {
    id: win

    screen: Quickshell.screens[0]
    color: "transparent"

    // --- Wayland Layer Shell Configuration ---
    // WlrLayer.Bottom places widgets on the desktop plane: above the wallpaper, behind all client windows.
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

    // --- Precision Input Masking (Click-Through) ---
    // Only the left and right widget columns capture pointer events.
    // All transparent desktop areas between and around them pass mouse events directly to the desktop.
    mask: Region {
        Region { item: leftColumn }
        Region { item: rightColumn }
    }

    // --- Left Column ---
    Item {
        id: leftColumn

        width: 360
        anchors {
            top: parent.top
            topMargin: Theme.spacing.huge
            bottom: parent.bottom
            bottomMargin: Theme.spacing.huge
            left: parent.left
            leftMargin: Theme.spacing.huge
        }

        // Prototype M1 surface for verification
        Card {
            id: leftPrototypeCard
            anchors.fill: parent
            baseOpacity: 0.80

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacing.md
                width: parent.width - Theme.padding.xl * 2

                Row {
                    spacing: Theme.spacing.sm
                    anchors.horizontalCenter: parent.horizontalCenter

                    Icon {
                        name: "widgets"
                        size: 28
                        color: Theme.primary
                    }

                    StyledText {
                        text: "Caelestia Widgets"
                        font.pixelSize: Theme.fonts.headline
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `Theme: ${Theme.schemeName} (${Theme.mode})`
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fonts.body
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.outlineVariant, 0.4)
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "LEFT COLUMN"
                    font.pixelSize: Theme.fonts.title
                    font.weight: Font.DemiBold
                    color: Theme.onSurface
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "• Clock & Date (M2)\n• Spotify Mini-Player (M3)\n• Screen-Time Tracker (M4/M5)"
                    color: Theme.alpha(Theme.onSurface, 0.75)
                    font.pixelSize: Theme.fonts.body
                    lineHeight: 1.4
                }

                Rectangle {
                    width: 48
                    height: 48
                    radius: Theme.rounding.sm
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        anchors.centerIn: parent
                        text: "M1"
                        color: Theme.onPrimary
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }

    // --- Right Column ---
    Item {
        id: rightColumn

        width: 360
        anchors {
            top: parent.top
            topMargin: Theme.spacing.huge
            bottom: parent.bottom
            bottomMargin: Theme.spacing.huge
            right: parent.right
            rightMargin: Theme.spacing.huge
        }

        // Prototype M1 surface for verification
        Card {
            id: rightPrototypeCard
            anchors.fill: parent
            baseOpacity: 0.80

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacing.md
                width: parent.width - Theme.padding.xl * 2

                Row {
                    spacing: Theme.spacing.sm
                    anchors.horizontalCenter: parent.horizontalCenter

                    Icon {
                        name: "apps"
                        size: 28
                        color: Theme.secondary
                    }

                    StyledText {
                        text: "Application Hub"
                        font.pixelSize: Theme.fonts.headline
                        font.weight: Font.Bold
                        color: Theme.secondary
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "RIGHT COLUMN"
                    font.pixelSize: Theme.fonts.title
                    font.weight: Font.DemiBold
                    color: Theme.onSurface
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.outlineVariant, 0.4)
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "• Most-Used Applications (M6)\n• Custom Quick Shortcuts (M7)\n• Running Indicators (M6)"
                    color: Theme.alpha(Theme.onSurface, 0.75)
                    font.pixelSize: Theme.fonts.body
                    lineHeight: 1.4
                }

                // Interactive test button to verify click handling inside mask
                Rectangle {
                    id: testBtn
                    width: 200
                    height: 44
                    radius: Theme.rounding.md
                    color: btnArea.pressed ? Theme.primaryContainer : (btnArea.containsMouse ? Theme.alpha(Theme.primary, 0.25) : Theme.alpha(Theme.primary, 0.15))
                    border.color: Theme.alpha(Theme.primary, 0.5)
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    property int clickCount: 0

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacing.sm

                        Icon {
                            name: "touch_app"
                            size: 18
                            color: Theme.primary
                        }

                        StyledText {
                            text: testBtn.clickCount === 0 ? "Test Click (M1)" : `Clicked ${testBtn.clickCount}x`
                            color: Theme.primary
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            testBtn.clickCount++;
                            console.log(`[DesktopLayer] Test button clicked: count = ${testBtn.clickCount}`);
                        }
                    }
                }
            }
        }
    }
}
