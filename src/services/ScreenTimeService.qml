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

    // Native ListModels for zero-flicker, smooth delegate updates
    ListModel { id: todayLm }
    ListModel { id: weekLm }
    property alias todayModel: todayLm
    property alias weekModel: weekLm

    property string todayTotalFormatted: "0m"
    property string weekTotalFormatted: "0m"

    // Wayland toplevel focus tracking
    readonly property var activeWindow: ToplevelManager.activeToplevel

    function getActiveAppId(): string {
        if (activeWindow && activeWindow.appId) {
            return String(activeWindow.appId);
        }
        if (ToplevelManager.toplevels) {
            for (let i = 0; i < ToplevelManager.toplevels.values.length; ++i) {
                const t = ToplevelManager.toplevels.values[i];
                if (t && t.activated && t.appId) {
                    return String(t.appId);
                }
            }
        }
        return "";
    }

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
        if (m === 0) return "<1m";
        return m + "m";
    }

    function resolveApp(rawId: string): var {
        if (!rawId) return null;
        const id = rawId.toLowerCase();

        // System / Shell surfaces to ignore
        if (id.includes("quickshell") || id.includes("caelestia-desktop-widgets") || id.includes("lock") || id.includes("desktop") || id.includes("screensaver")) {
            return null;
        }

        if (id.includes("antigravity")) {
            return { id: "antigravity", name: "Antigravity", icon: "/home/erebusstride/.local/bin/Antigravity/Google-Antigravity-Icon-White.png", fallback: "utilities-terminal", color: Theme.primary };
        }
        if (id.includes("chromium")) {
            return { id: "chromium", name: "Chromium", icon: "chromium", fallback: "web-browser", color: Theme.primaryFixed };
        }
        if (id.includes("brave")) {
            return { id: "brave", name: "Brave Browser", icon: "brave-desktop", fallback: "web-browser", color: Theme.primary };
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

    // Synchronize ListModel in-place: delegates are never destroyed, animations stay butter-smooth
    function syncListModel(lm, newItems) {
        while (lm.count > newItems.length) {
            lm.remove(lm.count - 1);
        }
        for (let i = 0; i < newItems.length; i++) {
            const item = newItems[i];
            const colStr = String(item.color || Theme.secondary);
            if (i < lm.count) {
                const cur = lm.get(i);
                if (cur.appId !== item.appId) lm.setProperty(i, "appId", item.appId);
                if (cur.name !== item.name) lm.setProperty(i, "name", item.name);
                if (cur.icon !== item.icon) lm.setProperty(i, "icon", item.icon);
                if (cur.fallback !== item.fallback) lm.setProperty(i, "fallback", item.fallback);
                if (cur.time !== item.time) lm.setProperty(i, "time", item.time);
                if (cur.pctStr !== item.pctStr) lm.setProperty(i, "pctStr", item.pctStr);
                if (Math.abs((cur.pct || 0) - item.pct) > 0.002) lm.setProperty(i, "pct", item.pct);
                if (cur.color !== colStr) lm.setProperty(i, "color", colStr);
            } else {
                lm.append({
                    appId: item.appId,
                    name: item.name,
                    icon: item.icon,
                    fallback: item.fallback,
                    time: item.time,
                    pctStr: item.pctStr,
                    pct: item.pct,
                    color: colStr
                });
            }
        }
    }

    // Handles 12:00 AM (Midnight) local day rollover
    function rollMidnight(newKey: string): void {
        console.log("[ScreenTime] Midnight rollover detected! Previous day:", todayKey, "New day:", newKey);

        if (!root.history) root.history = {};
        root.history[root.todayKey] = {
            total: root.todayTotalSeconds,
            apps: Object.assign({}, root.todayApps)
        };

        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - 30);
        const cutoffKey = getLocalDayKey(cutoff);
        for (const k in root.history) {
            if (k < cutoffKey) {
                delete root.history[k];
            }
        }

        root.todayKey = newKey;
        root.todayApps = {};
        root.todayTotalSeconds = 0;

        recalculateModels();
        save();
    }

    function recalculateModels(): void {
        // --- 1. Compute Today's List ---
        const todayEntries = [];
        const appMap = root.todayApps || {};
        let calculatedTodayTotal = 0;
        for (const appId in appMap) {
            const secs = appMap[appId];
            if (secs > 0) {
                calculatedTodayTotal += secs;
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

        root.todayTotalSeconds = calculatedTodayTotal;
        todayEntries.sort((a, b) => b.seconds - a.seconds);

        const totalSecs = Math.max(root.todayTotalSeconds, 1);
        const topToday = [];
        const maxToday = Math.min(25, todayEntries.length);
        for (let i = 0; i < maxToday; i++) {
            const e = todayEntries[i];
            const pct = Math.min(1.0, Math.max(0.001, e.seconds / totalSecs));
            const pctDisplay = pct >= 0.01 ? (Math.round(pct * 100) + "%") : "<1%";
            topToday.push({
                appId: e.id,
                name: e.name,
                icon: e.icon,
                fallback: e.fallback,
                time: formatDuration(e.seconds),
                pct: pct,
                pctStr: pctDisplay,
                color: e.color
            });
        }
        syncListModel(todayLm, topToday);
        root.todayTotalFormatted = formatDuration(root.todayTotalSeconds);

        // --- 2. Compute Week's List (Past 7 Days from history + today) ---
        const weekApps = {};
        let weekTotal = root.todayTotalSeconds;
        for (const id in appMap) {
            weekApps[id] = (weekApps[id] || 0) + appMap[id];
        }

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
        const maxWeek = Math.min(25, weekEntries.length);
        for (let i = 0; i < maxWeek; i++) {
            const e = weekEntries[i];
            const pct = Math.min(1.0, Math.max(0.001, e.seconds / safeWeekTotal));
            const pctDisplay = pct >= 0.01 ? (Math.round(pct * 100) + "%") : "<1%";
            topWeek.push({
                appId: e.id,
                name: e.name,
                icon: e.icon,
                fallback: e.fallback,
                time: formatDuration(e.seconds),
                pct: pct,
                pctStr: pctDisplay,
                color: e.color
            });
        }
        syncListModel(weekLm, topWeek);
        root.weekTotalFormatted = formatDuration(weekTotal);
    }

    property int tickCounter: 0

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
            const activeId = root.getActiveAppId();
            const app = root.resolveApp(activeId);
            if (app) {
                if (!root.todayApps) root.todayApps = {};
                root.todayApps[app.id] = (root.todayApps[app.id] || 0) + 1;
                root.todayTotalSeconds += 1;
            }

            root.tickCounter += 1;
            // Update smoothly every 2 seconds without recreating items
            if (root.tickCounter % 2 === 0) {
                root.recalculateModels();
            }
        }
    }

    // Auto-save to disk every 15 seconds
    property var saveTimer: Timer {
        interval: 15000
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
                    root.todayKey = localKey;
                    root.todayTotalSeconds = data.todayTotal || 0;
                    root.todayApps = data.todayApps || {};
                } else {
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
                initEmptyData(localKey);
            }
        } else {
            // First run: clean start with 0 data
            initEmptyData(localKey);
        }
        root.recalculateModels();
    }

    function initEmptyData(localKey: string): void {
        root.todayKey = localKey;
        root.todayApps = {};
        root.todayTotalSeconds = 0;
        root.history = {};
    }

    Component.onCompleted: {
        load();
    }
}
