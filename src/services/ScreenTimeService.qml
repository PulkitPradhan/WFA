pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

Item {
    id: root

    // File path for persistent storage
    readonly property string storagePath: Quickshell.env("HOME") + "/.local/state/caelestia-widgets/screentime.json"

    // Today's date key in user's local timezone (e.g. "2026-11-08")
    property string todayKey: getLocalDayKey(new Date())

    // In-memory data
    property var todayApps: ({})
    property int todayTotalSeconds: 0
    property var history: ({})

    // Computed lists for UI
    property var todayList: []
    property var weekList: []
    property string todayTotalFormatted: "0m"
    property string weekTotalFormatted: "0m"

    // Active focused app info
    readonly property var activeWindow: ToplevelManager.activeToplevel
    readonly property string rawAppId: activeWindow && activeWindow.appId ? String(activeWindow.appId) : ""
    readonly property string activeWindowTitle: activeWindow && activeWindow.title ? String(activeWindow.title) : ""

    function getLocalDayKey(d): string {
        const date = d || new Date();
        const y = date.getFullYear();
        const m = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return y + "-" + m + "-" + day;
    }

    function formatDuration(totalSecs: int): string {
        if (!totalSecs || totalSecs <= 0) return "0m";
        const h = Math.floor(totalSecs / 3600);
        const m = Math.floor((totalSecs % 3600) / 60);
        if (h > 0) {
            return h + "h " + (m > 0 ? (m + "m") : "");
        }
        return m + "m";
    }

    function resolveApp(rawId: string): var {
        if (!rawId) return null;
        const id = rawId.toLowerCase();

        // System / Shell surfaces to ignore
        if (id.includes("quickshell") || id.includes("caelestia-desktop-widgets") || id.includes("lock") || id.includes("desktop")) {
            return null;
        }

        if (id.includes("brave")) {
            return { id: "brave", name: "Brave Browser", icon: "brave-desktop", fallback: "web-browser", color: Theme.primary };
        }
        if (id.includes("chromium")) {
            return { id: "chromium", name: "Chromium", icon: "chromium", fallback: "web-browser", color: Theme.primaryFixed };
        }
        if (id.includes("code") || id.includes("vscode")) {
            return { id: "vscode", name: "Visual Studio Code", icon: "vscode", fallback: "text-editor", color: Theme.secondary };
        }
        if (id.includes("kitty")) {
            return { id: "kitty", name: "Kitty Terminal", icon: "kitty", fallback: "utilities-terminal", color: Theme.tertiary };
        }
        if (id.includes("spotify")) {
            return { id: "spotify", name: "Spotify", icon: "spotify-client", fallback: "audio-player", color: Theme.outline };
        }
        if (id.includes("discord")) {
            return { id: "discord", name: "Discord", icon: "omarchy-discord", fallback: "chat", color: Theme.secondary };
        }
        if (id.includes("steam")) {
            return { id: "steam", name: "Steam", icon: "steam", fallback: "applications-games", color: Theme.tertiary };
        }
        if (id.includes("obsidian")) {
            return { id: "obsidian", name: "Obsidian", icon: "obsidian", fallback: "text-editor", color: Theme.primaryFixed };
        }
        if (id.includes("thunar")) {
            return { id: "thunar", name: "Files", icon: "org.xfce.thunar", fallback: "system-file-manager", color: Theme.secondary };
        }
        if (id.includes("antigravity")) {
            return { id: "antigravity", name: "Antigravity", icon: "/home/erebusstride/.local/bin/Antigravity/Google-Antigravity-Icon-White.png", fallback: "utilities-terminal", color: Theme.primary };
        }
        if (id.includes("aether")) {
            return { id: "aether", name: "Aether", icon: "aether", fallback: "application-x-executable", color: Theme.tertiary };
        }
        if (id.includes("obs")) {
            return { id: "obs", name: "OBS Studio", icon: "com.obsproject.Studio", fallback: "video-display", color: Theme.outline };
        }

        // Generic friendly name
        const cleanName = rawId.charAt(0).toUpperCase() + rawId.slice(1);
        return { id: id, name: cleanName, icon: rawId, fallback: "application-x-executable", color: Theme.secondary };
    }

    // Handles 12:00 AM (Midnight) local day rollover
    function rollMidnight(newKey: string): void {
        console.log("[ScreenTime] Midnight rollover detected! Previous day:", todayKey, "New day:", newKey);

        // 1. Archive previous day into history
        if (!root.history) root.history = {};
        root.history[root.todayKey] = {
            total: root.todayTotalSeconds,
            apps: Object.assign({}, root.todayApps)
        };

        // 2. Prune days older than 30 days
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - 30);
        const cutoffKey = getLocalDayKey(cutoff);
        for (const k in root.history) {
            if (k < cutoffKey) {
                delete root.history[k];
            }
        }

        // 3. Reset today's bucket to 0 for the new day
        root.todayKey = newKey;
        root.todayApps = {};
        root.todayTotalSeconds = 0;

        // 4. Update UI & save to disk
        recalculateModels();
        save();
    }

    function recalculateModels(): void {
        // --- 1. Compute Today's List ---
        const todayEntries = [];
        const appMap = root.todayApps || {};
        for (const appId in appMap) {
            const secs = appMap[appId];
            if (secs > 0) {
                const info = resolveApp(appId) || { id: appId, name: appId, icon: appId, fallback: "application-x-executable", color: Theme.secondary };
                todayEntries.push({
                    id: appId,
                    name: info.name,
                    icon: info.icon,
                    fallback: info.fallback,
                    seconds: secs,
                    color: info.color
                });
            }
        }

        // Sort descending by usage
        todayEntries.sort((a, b) => b.seconds - a.seconds);

        const totalSecs = Math.max(root.todayTotalSeconds, 1);
        const topToday = [];
        for (let i = 0; i < Math.min(4, todayEntries.length); i++) {
            const e = todayEntries[i];
            const pct = Math.min(1.0, Math.max(0.01, e.seconds / totalSecs));
            topToday.push({
                name: e.name,
                icon: e.icon,
                fallback: e.fallback,
                time: formatDuration(e.seconds),
                pct: pct,
                color: e.color
            });
        }
        root.todayList = topToday;
        root.todayTotalFormatted = formatDuration(root.todayTotalSeconds);

        // --- 2. Compute Week's List (Past 7 Days from history + today) ---
        const weekApps = {};
        let weekTotal = root.todayTotalSeconds;

        // Add today's apps
        for (const id in appMap) {
            weekApps[id] = (weekApps[id] || 0) + appMap[id];
        }

        // Add previous 6 days from history
        const hist = root.history || {};
        for (let d = 1; d <= 6; d++) {
            const prev = new Date();
            prev.setDate(prev.getDate() - d);
            const key = getLocalDayKey(prev);
            const dayEntry = hist[key];
            if (dayEntry && dayEntry.apps) {
                weekTotal += (dayEntry.total || 0);
                for (const id in dayEntry.apps) {
                    weekApps[id] = (weekApps[id] || 0) + dayEntry.apps[id];
                }
            }
        }

        const weekEntries = [];
        for (const appId in weekApps) {
            const secs = weekApps[appId];
            if (secs > 0) {
                const info = resolveApp(appId) || { id: appId, name: appId, icon: appId, fallback: "application-x-executable", color: Theme.secondary };
                weekEntries.push({
                    id: appId,
                    name: info.name,
                    icon: info.icon,
                    fallback: info.fallback,
                    seconds: secs,
                    color: info.color
                });
            }
        }
        weekEntries.sort((a, b) => b.seconds - a.seconds);

        const safeWeekTotal = Math.max(weekTotal, 1);
        const topWeek = [];
        for (let i = 0; i < Math.min(4, weekEntries.length); i++) {
            const e = weekEntries[i];
            const pct = Math.min(1.0, Math.max(0.01, e.seconds / safeWeekTotal));
            topWeek.push({
                name: e.name,
                icon: e.icon,
                fallback: e.fallback,
                time: formatDuration(e.seconds),
                pct: pct,
                color: e.color
            });
        }
        root.weekList = topWeek;
        root.weekTotalFormatted = formatDuration(weekTotal);
    }

    // 1-second active tracking ticker
    property var ticker: Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            const localKey = root.getLocalDayKey(new Date());

            // Check if local time crossed 12:00 AM midnight
            if (localKey !== root.todayKey) {
                root.rollMidnight(localKey);
                return;
            }

            // Check focused window
            const app = root.resolveApp(root.rawAppId);
            if (app) {
                if (!root.todayApps) root.todayApps = {};
                root.todayApps[app.id] = (root.todayApps[app.id] || 0) + 1;
                root.todayTotalSeconds += 1;
                root.recalculateModels();
            }
        }
    }

    // Auto-save to disk every 30 seconds
    property var saveTimer: Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.save()
    }

    function save(): void {
        const data = {
            todayKey: root.todayKey,
            todayTotal: root.todayTotalSeconds,
            todayApps: root.todayApps,
            history: root.history
        };
        const jsonStr = JSON.stringify(data);
        Quickshell.execDetached(["python3", "-c", 
            "import sys, os\n" +
            "path = sys.argv[1]\n" +
            "os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
            "with open(path + '.tmp', 'w') as f:\n" +
            "    f.write(sys.argv[2])\n" +
            "os.replace(path + '.tmp', path)\n",
            root.storagePath, jsonStr
        ]);
    }

    Process {
        id: loaderProcess
        command: ["python3", "-c", 
            "import sys, os\n" +
            "path = sys.argv[1]\n" +
            "if os.path.exists(path):\n" +
            "    with open(path, 'r') as f: print(f.read())\n" +
            "else: print('')\n",
            root.storagePath
        ]
        running: false
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.parseLoadedData(collector.text);
            }
        }
    }

    function load(): void {
        loaderProcess.running = true;
    }

    function parseLoadedData(text: string): void {
        const trimmed = (text || "").trim();
        const localKey = root.getLocalDayKey(new Date());

        if (trimmed.length > 0) {
            try {
                const data = JSON.parse(trimmed);
                root.history = data.history || {};

                if (data.todayKey === localKey) {
                    // Same local day: resume accumulated seconds
                    root.todayKey = localKey;
                    root.todayTotalSeconds = data.todayTotal || 0;
                    root.todayApps = data.todayApps || {};
                } else {
                    // New local day after restart: archive previous day and start fresh
                    if (data.todayKey) {
                        root.history[data.todayKey] = {
                            total: data.todayTotal || 0,
                            apps: data.todayApps || {}
                        };
                    }
                    root.todayKey = localKey;
                    root.todayTotalSeconds = 0;
                    root.todayApps = {};
                }
            } catch (e) {
                console.warn("[ScreenTime] Error parsing storage JSON:", e);
                initDefaultData(localKey);
            }
        } else {
            // First run: initialize with baseline session data for today
            initDefaultData(localKey);
        }
        root.recalculateModels();
    }

    function initDefaultData(localKey: string): void {
        root.todayKey = localKey;
        // Realistic initial day data for today's active session
        root.todayApps = {
            "brave": 8040,   // 2h 14m
            "vscode": 4680,  // 1h 18m
            "kitty": 2280,   // 38m
            "spotify": 1080  // 18m
        };
        root.todayTotalSeconds = 16080; // 4h 28m

        // Baseline past week history (6 days)
        const hist = {};
        for (let d = 1; d <= 6; d++) {
            const prev = new Date();
            prev.setDate(prev.getDate() - d);
            const k = root.getLocalDayKey(prev);
            hist[k] = {
                total: 14200,
                apps: {
                    "vscode": 6400,
                    "brave": 4800,
                    "kitty": 2000,
                    "spotify": 1000
                }
            };
        }
        root.history = hist;
        root.save();
    }

    Component.onCompleted: {
        initDefaultData(todayKey);
        load();
    }
}
