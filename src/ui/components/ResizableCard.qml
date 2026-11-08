pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../theme"

Rectangle {
    id: root

    property string widgetId: ""
    property real minWidth: 300
    property real maxWidth: 1200
    property real minHeight: 110
    property real maxHeight: 900

    property real baseOpacity: Theme.transparency.layers + 0.05
    property bool hoverable: true
    readonly property bool isHovered: hoverArea.containsMouse

    color: Theme.alpha(Theme.surfaceContainer, baseOpacity)
    radius: Theme.rounding.xl
    border.color: Theme.alpha(Theme.outlineVariant, isHovered ? 0.30 : 0.12)
    border.width: 1

    signal geometryChangedByUser()

    Behavior on color { ColorAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easingCurve } }
    Behavior on border.color { ColorAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easingCurve } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: root.hoverable
        hoverEnabled: root.hoverable
        acceptedButtons: Qt.NoButton
    }

    // ==========================================
    // 1. DIRECT DRAG TO MOVE (Grab anywhere to place)
    // ==========================================
    property bool isDraggingWidget: false
    property real dragStartScreenX: 0
    property real dragStartScreenY: 0
    property real dragStartWidgetX: 0
    property real dragStartWidgetY: 0

    function startMoving(screenX, screenY) {
        isDraggingWidget = true;
        dragStartWidgetX = root.x;
        dragStartWidgetY = root.y;
        dragStartScreenX = screenX;
        dragStartScreenY = screenY;
    }

    function moveWidget(screenX, screenY) {
        if (isDraggingWidget && root.parent) {
            const dx = screenX - dragStartScreenX;
            const dy = screenY - dragStartScreenY;
            const maxX = Math.max(0, root.parent.width - root.width);
            const maxY = Math.max(0, root.parent.height - root.height);
            root.x = Math.max(0, Math.min(maxX, dragStartWidgetX + dx));
            root.y = Math.max(0, Math.min(maxY, dragStartWidgetY + dy));
        }
    }

    function stopMoving() {
        if (isDraggingWidget) {
            isDraggingWidget = false;
            root.geometryChangedByUser();
        }
    }

    MouseArea {
        id: baseDragArea
        anchors.fill: parent
        z: 0 // Card background plane: catches clicks on background, margins, text, and artwork
        acceptedButtons: Qt.LeftButton
        cursorShape: root.isDraggingWidget ? Qt.ClosedHandCursor : Qt.ArrowCursor

        onPressed: (mouse) => {
            const p = mapToItem(root.parent, mouse.x, mouse.y);
            root.startMoving(p.x, p.y);
        }

        onPositionChanged: (mouse) => {
            if (pressed && root.isDraggingWidget) {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                root.moveWidget(p.x, p.y);
            }
        }

        onReleased: (mouse) => {
            root.stopMoving();
        }

        onCanceled: {
            root.stopMoving();
        }
    }

    // ==========================================
    // 2. CORNER & EDGE RESIZE HITBOXES (z: 1000)
    // ==========================================
    readonly property int edgeHitSize: 12
    readonly property int cornerHitSize: 22

    Item {
        id: resizeHandles
        anchors.fill: parent
        z: 1000

        property real startX: 0
        property real startY: 0
        property real initW: 0
        property real initH: 0
        property real initX: 0
        property real initY: 0

        function beginResize(screenX, screenY) {
            initX = root.x;
            initY = root.y;
            initW = root.width;
            initH = root.height;
            startX = screenX;
            startY = screenY;
        }

        function endResize() {
            root.geometryChangedByUser();
        }

        // --- Top Edge ---
        MouseArea {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.cornerHitSize
            anchors.rightMargin: root.cornerHitSize
            height: root.edgeHitSize
            cursorShape: Qt.SizeVerCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dy = p.y - resizeHandles.startY;
                    const newH = Math.max(root.minHeight, Math.min(root.maxHeight, resizeHandles.initH - dy));
                    root.y = resizeHandles.initY + (resizeHandles.initH - newH);
                    root.height = newH;
                }
            }
            onReleased: resizeHandles.endResize()
        }

        // --- Bottom Edge ---
        MouseArea {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.cornerHitSize
            anchors.rightMargin: root.cornerHitSize
            height: root.edgeHitSize
            cursorShape: Qt.SizeVerCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dy = p.y - resizeHandles.startY;
                    root.height = Math.max(root.minHeight, Math.min(root.maxHeight, resizeHandles.initH + dy));
                }
            }
            onReleased: resizeHandles.endResize()
        }

        // --- Left Edge ---
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: root.cornerHitSize
            anchors.bottomMargin: root.cornerHitSize
            width: root.edgeHitSize
            cursorShape: Qt.SizeHorCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dx = p.x - resizeHandles.startX;
                    const newW = Math.max(root.minWidth, Math.min(root.maxWidth, resizeHandles.initW - dx));
                    root.x = resizeHandles.initX + (resizeHandles.initW - newW);
                    root.width = newW;
                }
            }
            onReleased: resizeHandles.endResize()
        }

        // --- Right Edge ---
        MouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: root.cornerHitSize
            anchors.bottomMargin: root.cornerHitSize
            width: root.edgeHitSize
            cursorShape: Qt.SizeHorCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dx = p.x - resizeHandles.startX;
                    root.width = Math.max(root.minWidth, Math.min(root.maxWidth, resizeHandles.initW + dx));
                }
            }
            onReleased: resizeHandles.endResize()
        }

        // --- Top-Left Corner ---
        MouseArea {
            anchors.top: parent.top
            anchors.left: parent.left
            width: root.cornerHitSize
            height: root.cornerHitSize
            cursorShape: Qt.SizeFDiagCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dx = p.x - resizeHandles.startX;
                    const dy = p.y - resizeHandles.startY;
                    const newW = Math.max(root.minWidth, Math.min(root.maxWidth, resizeHandles.initW - dx));
                    const newH = Math.max(root.minHeight, Math.min(root.maxHeight, resizeHandles.initH - dy));
                    root.x = resizeHandles.initX + (resizeHandles.initW - newW);
                    root.y = resizeHandles.initY + (resizeHandles.initH - newH);
                    root.width = newW;
                    root.height = newH;
                }
            }
            onReleased: resizeHandles.endResize()
        }

        // --- Top-Right Corner ---
        MouseArea {
            anchors.top: parent.top
            anchors.right: parent.right
            width: root.cornerHitSize
            height: root.cornerHitSize
            cursorShape: Qt.SizeBDiagCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dx = p.x - resizeHandles.startX;
                    const dy = p.y - resizeHandles.startY;
                    const newH = Math.max(root.minHeight, Math.min(root.maxHeight, resizeHandles.initH - dy));
                    root.y = resizeHandles.initY + (resizeHandles.initH - newH);
                    root.width = Math.max(root.minWidth, Math.min(root.maxWidth, resizeHandles.initW + dx));
                    root.height = newH;
                }
            }
            onReleased: resizeHandles.endResize()
        }

        // --- Bottom-Left Corner ---
        MouseArea {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: root.cornerHitSize
            height: root.cornerHitSize
            cursorShape: Qt.SizeBDiagCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dx = p.x - resizeHandles.startX;
                    const dy = p.y - resizeHandles.startY;
                    const newW = Math.max(root.minWidth, Math.min(root.maxWidth, resizeHandles.initW - dx));
                    root.x = resizeHandles.initX + (resizeHandles.initW - newW);
                    root.width = newW;
                    root.height = Math.max(root.minHeight, Math.min(root.maxHeight, resizeHandles.initH + dy));
                }
            }
            onReleased: resizeHandles.endResize()
        }

        // --- Bottom-Right Corner ---
        MouseArea {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: root.cornerHitSize
            height: root.cornerHitSize
            cursorShape: Qt.SizeFDiagCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: (mouse) => {
                const p = mapToItem(root.parent, mouse.x, mouse.y);
                resizeHandles.beginResize(p.x, p.y);
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.parent) {
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    const dx = p.x - resizeHandles.startX;
                    const dy = p.y - resizeHandles.startY;
                    root.width = Math.max(root.minWidth, Math.min(root.maxWidth, resizeHandles.initW + dx));
                    root.height = Math.max(root.minHeight, Math.min(root.maxHeight, resizeHandles.initH + dy));
                }
            }
            onReleased: resizeHandles.endResize()
        }
    }
}
