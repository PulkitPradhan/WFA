#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH="$PROJECT_ROOT/shell.qml"
LOG_FILE="/tmp/caelestia-widgets.log"

find_widget_pid() {
    pgrep -f "quickshell.*$PROJECT_ROOT/shell.qml" || true
}

stop() {
    local pid
    pid="$(find_widget_pid)"
    if [[ -n "$pid" ]]; then
        echo "Stopping existing widget instance (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        for _ in {1..20}; do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done
        kill -9 "$pid" 2>/dev/null || true
    fi
}

start() {
    stop
    echo "Starting Caelestia Desktop Widgets..."
    echo "Config: $CONFIG_PATH"
    echo "Logs: $LOG_FILE"

    # Pre-register Hyprland layer blur rules before surface binds
    hyprctl --batch "eval hl.layer_rule({ match = { namespace = '^caelestia-desktop-widgets$' }, blur = true, ignore_alpha = 0.15 })" >/dev/null 2>&1 || true

    # Launch detached with setsid to prevent SIGHUP on script exit
    QS_ICON_THEME=Adwaita \
    setsid quickshell --path "$CONFIG_PATH" > "$LOG_FILE" 2>&1 < /dev/null &
    local new_pid=$!
    sleep 0.8

    if kill -0 "$new_pid" 2>/dev/null; then
        echo "Widgets successfully started with PID: $new_pid"
        # Confirm layer rule application
        hyprctl --batch "eval hl.layer_rule({ match = { namespace = '^caelestia-desktop-widgets$' }, blur = true, ignore_alpha = 0.15 })" >/dev/null 2>&1 || true
    else
        echo "Failed to start widgets. Check log: $LOG_FILE"
        cat "$LOG_FILE"
        exit 1
    fi
}

case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        echo "Widgets stopped."
        ;;
    restart)
        start
        ;;
    status)
        pid="$(find_widget_pid)"
        if [[ -n "$pid" ]]; then
            echo "Widgets running (PID: $pid)"
        else
            echo "Widgets not running."
        fi
        ;;
    *)
        echo "Usage: $0 [start|stop|restart|status]"
        exit 1
        ;;
esac
