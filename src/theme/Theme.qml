pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // --- State & Status ---
    property string schemeName: "default-dark"
    property string flavour: "caelestia"
    property string mode: "dark"
    property bool isLoaded: false

    // --- Material Design 3 Palette (m3-prefixed to avoid QML signal-handler name clashes) ---
    property color m3primary: "#a26695"
    property color m3onPrimary: "#000000"
    property color m3primaryContainer: "#392434"
    property color m3onPrimaryContainer: "#af9cc2"
    property color m3primaryFixed: "#ad93ba"

    property color m3secondary: "#808080"
    property color m3onSecondary: "#000000"
    property color m3secondaryContainer: "#2d2d2d"
    property color m3onSecondaryContainer: "#a2a6ba"

    property color m3tertiary: "#808080"
    property color m3onTertiary: "#000000"
    property color m3tertiaryContainer: "#2d2d2d"
    property color m3onTertiaryContainer: "#a2a6ba"

    property color m3background: "#000000"
    property color m3onBackground: "#b8c0e0"

    property color m3surface: "#000000"
    property color m3surfaceDim: "#000000"
    property color m3surfaceBright: "#25262d"
    property color m3surfaceContainerLowest: "#040404"
    property color m3surfaceContainerLow: "#090a0b"
    property color m3surfaceContainer: "#0f0f12"
    property color m3surfaceContainerHigh: "#16171b"
    property color m3surfaceContainerHighest: "#1d1f24"

    property color m3onSurface: "#b8c0e0"
    property color m3surfaceVariant: "#1a1b1f"
    property color m3onSurfaceVariant: "#8a90a8"

    property color m3outline: "#5c6070"
    property color m3outlineVariant: "#2e3038"
    property color m3shadow: "#000000"
    property color m3scrim: "#000000"

    property color m3error: "#ba1a1a"
    property color m3onError: "#ffffff"
    property color m3errorContainer: "#93000a"
    property color m3onErrorContainer: "#ffdad6"

    property color m3success: "#558b2f"
    property color m3onSuccess: "#ffffff"
    property color m3successContainer: "#33691e"
    property color m3onSuccessContainer: "#dcedc8"

    // --- Clean Convenience Aliases ---
    readonly property color primary: m3primary
    readonly property color primaryContainer: m3primaryContainer
    readonly property color primaryFixed: m3primaryFixed

    readonly property color secondary: m3secondary
    readonly property color secondaryContainer: m3secondaryContainer

    readonly property color tertiary: m3tertiary
    readonly property color tertiaryContainer: m3tertiaryContainer

    readonly property color background: m3background

    readonly property color surfaceColor: m3surface
    readonly property color surfaceDim: m3surfaceDim
    readonly property color surfaceBright: m3surfaceBright
    readonly property color surfaceContainerLowest: m3surfaceContainerLowest
    readonly property color surfaceContainerLow: m3surfaceContainerLow
    readonly property color surfaceContainer: m3surfaceContainer
    readonly property color surfaceContainerHigh: m3surfaceContainerHigh
    readonly property color surfaceContainerHighest: m3surfaceContainerHighest
    readonly property color surfaceVariant: m3surfaceVariant

    // Text / Foreground colors (Safe from QML on* signal clashes)
    readonly property color text: m3onSurface
    readonly property color textPrimary: m3onSurface
    readonly property color textSecondary: m3onSurfaceVariant
    readonly property color textMuted: m3onSurfaceVariant
    readonly property color textOnPrimary: m3onPrimary
    readonly property color textOnSecondary: m3onSecondary

    // Direct palette access matching Caelestia
    readonly property color onSurface: m3onSurface
    readonly property color onSurfaceVariant: m3onSurfaceVariant
    readonly property color onPrimary: m3onPrimary
    readonly property color onSecondary: m3onSecondary
    readonly property color onBackground: m3onBackground

    readonly property color outline: m3outline
    readonly property color outlineVariant: m3outlineVariant
    readonly property color shadow: m3shadow
    readonly property color scrim: m3scrim

    readonly property color error: m3error
    readonly property color success: m3success

    // --- Utility Methods ---
    function alpha(c: color, a: real): color {
        if (!c)
            return Qt.rgba(0, 0, 0, a);
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // --- Design Tokens (Independent, 100% Caelestia Shell Match) ---
    readonly property QtObject transparency: QtObject {
        readonly property bool enabled: true
        readonly property real base: 0.85
        readonly property real layers: 0.40
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 20
        readonly property int xxl: 24
        readonly property int huge: 32
    }

    readonly property QtObject rounding: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int largeIncreased: 20
        readonly property int xl: 28
        readonly property int xxl: 32
        readonly property int xxxl: 48
        readonly property int full: 9999
    }

    readonly property QtObject padding: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 20
        readonly property int xxl: 24
        readonly property int huge: 32
    }

    readonly property QtObject fonts: QtObject {
        readonly property string family: "Google Sans Flex"
        readonly property string familyClock: "Rubik"
        readonly property string familyMono: "JetBrainsMono Nerd Font"
        readonly property string familyIcon: "Material Symbols Rounded"

        readonly property int small: 11
        readonly property int smaller: 12
        readonly property int normal: 13
        readonly property int larger: 15
        readonly property int large: 18
        readonly property int extraLarge: 28
        readonly property int clock: 54
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 400
        readonly property int easingCurve: Easing.OutCubic
    }

    function reloadHyprRules(): void {
        Quickshell.execDetached(["hyprctl", "--batch", "eval hl.layer_rule({ match = { namespace = '^caelestia-desktop-widgets$' }, blur = true, ignore_alpha = 0.15 })"]);
    }

    // --- Dynamic File Watcher for Caelestia Theme Scheme ---
    readonly property FileView _fileView: FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        onFileChanged: {
            reload();
            root.reloadHyprRules();
        }
        onLoaded: {
            root._applyScheme(text());
            root.reloadHyprRules();
        }
    }

    function _applyScheme(jsonText: string): void {
        if (!jsonText || jsonText.trim().length === 0)
            return;

        try {
            const data = JSON.parse(jsonText);
            if (!data || !data.colours) {
                console.warn("[ThemeService] Incomplete scheme structure, retaining fallback defaults");
                return;
            }

            root.schemeName = data.name ?? "custom";
            root.flavour = data.flavour ?? "omarchy";
            root.mode = data.mode ?? "dark";

            const c = data.colours;
            function pick(key: string, fallback: color): color {
                if (c[key]) {
                    const hex = c[key].startsWith("#") ? c[key] : `#${c[key]}`;
                    return hex;
                }
                return fallback;
            }

            root.m3primary = pick("primary", root.m3primary);
            root.m3onPrimary = pick("onPrimary", root.m3onPrimary);
            root.m3primaryContainer = pick("primaryContainer", root.m3primaryContainer);
            root.m3onPrimaryContainer = pick("onPrimaryContainer", root.m3onPrimaryContainer);
            root.m3primaryFixed = pick("primaryFixed", root.m3primaryFixed);

            root.m3secondary = pick("secondary", root.m3secondary);
            root.m3onSecondary = pick("onSecondary", root.m3onSecondary);
            root.m3secondaryContainer = pick("secondaryContainer", root.m3secondaryContainer);
            root.m3onSecondaryContainer = pick("onSecondaryContainer", root.m3onSecondaryContainer);

            root.m3tertiary = pick("tertiary", root.m3tertiary);
            root.m3onTertiary = pick("onTertiary", root.m3onTertiary);
            root.m3tertiaryContainer = pick("tertiaryContainer", root.m3tertiaryContainer);
            root.m3onTertiaryContainer = pick("onTertiaryContainer", root.m3onTertiaryContainer);

            root.m3background = pick("background", root.m3background);
            root.m3onBackground = pick("onBackground", root.m3onBackground);

            root.m3surface = pick("surface", root.m3surface);
            root.m3surfaceDim = pick("surfaceDim", root.m3surfaceDim);
            root.m3surfaceBright = pick("surfaceBright", root.m3surfaceBright);
            root.m3surfaceContainerLowest = pick("surfaceContainerLowest", root.m3surfaceContainerLowest);
            root.m3surfaceContainerLow = pick("surfaceContainerLow", root.m3surfaceContainerLow);
            root.m3surfaceContainer = pick("surfaceContainer", root.m3surfaceContainer);
            root.m3surfaceContainerHigh = pick("surfaceContainerHigh", root.m3surfaceContainerHigh);
            root.m3surfaceContainerHighest = pick("surfaceContainerHighest", root.m3surfaceContainerHighest);

            root.m3onSurface = pick("onSurface", root.m3onSurface);
            root.m3surfaceVariant = pick("surfaceVariant", root.m3surfaceVariant);
            root.m3onSurfaceVariant = pick("onSurfaceVariant", root.m3onSurfaceVariant);

            root.m3outline = pick("outline", root.m3outline);
            root.m3outlineVariant = pick("outlineVariant", root.m3outlineVariant);
            root.m3shadow = pick("shadow", root.m3shadow);
            root.m3scrim = pick("scrim", root.m3scrim);

            root.m3error = pick("error", root.m3error);
            root.m3onError = pick("onError", root.m3onError);
            root.m3errorContainer = pick("errorContainer", root.m3errorContainer);
            root.m3onErrorContainer = pick("onErrorContainer", root.m3onErrorContainer);

            root.m3success = pick("success", root.m3success);
            root.m3onSuccess = pick("onSuccess", root.m3onSuccess);
            root.m3successContainer = pick("successContainer", root.m3successContainer);
            root.m3onSuccessContainer = pick("onSuccessContainer", root.m3onSuccessContainer);

            root.isLoaded = true;
            console.log(`[ThemeService] Loaded theme '${root.schemeName}' (${root.mode}) successfully`);
        } catch (err) {
            console.warn(`[ThemeService] Failed to parse scheme.json: ${err}. Keeping fallback palette.`);
        }
    }
}
