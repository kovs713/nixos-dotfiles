import QtQuick

import "." as Core

Item {
    id: root

    required property int index

    property real swipeThreshold: 72

    signal swiped

    property bool flying: false

    property real flyX: 0.0

    readonly property real swipeOffset: {
        if (Core.SwipeState.index < 0)
            return 0;

        const distance = Core.SwipeState.distance;
        const difference = Math.abs(Core.SwipeState.index - root.index);

        if (difference === 0)
            return distance;

        if (Math.abs(distance) > root.swipeThreshold)
            return 0;

        if (difference === 1)
            return distance * 0.3;

        if (difference === 2)
            return distance * 0.1;

        return 0;
    }

    readonly property real offset: root.flying ? root.flyX : root.swipeOffset

    readonly property real travelFade: root.offset === 0
        ? 1.0
        : Math.max(0.3, 1.0 - Math.abs(root.offset) / (root.width * 1.6))

    transform: Translate {
        x: root.offset
    }

    DragHandler {
        target: null

        dragThreshold: 8

        yAxis.enabled: false

        onActiveChanged: {
            if (active) {
                Core.SwipeState.grab(root.index);

                return;
            }

            if (Math.abs(Core.SwipeState.distance) > root.swipeThreshold) {
                root.fling(root.swipeOffset < 0);
                return;
            }

            Core.SwipeState.release();
        }

        onTranslationChanged: {
            if (active)
                Core.SwipeState.move(activeTranslation.x);
        }
    }

    function fling(left) {
        root.flying = true;

        throwAnim.to = (left ? -1 : 1) * (root.width + 60);
        throwAnim.running = true;
    }

    NumberAnimation {
        id: throwAnim

        target: root
        property: "flyX"

        duration: Core.Theme.durBase

        easing.type: Easing.InQuad

        onFinished: {
            root.flying = false;
            root.flyX = 0.0;

            Core.SwipeState.release();

            root.swiped();
        }
    }
}
