import QtQuick

import "." as Core

// SwipeRow
//
// Drag a row sideways to throw it away.
//
// The whole gesture used to be written twice, once in the toast overlay and once
// in the notification centre: the threshold, the decaying 1.0 / 0.3 / 0.1 that
// makes a stack read as a stack of cards, the DragHandler, the throw and the
// release. The two copies had drifted — the centre carried a `flying` / `flyX`
// pair and a fade the toast did not have, and the toast's throw drove the
// Translate directly, which is the recycling bug the centre's comment describes.
//
// It is an Item and not a styled row, so the chrome stays with the caller. What
// it owns is the gesture: put it at the root of a delegate (the centre) or
// around the card (the toast, whose enter and exit animations already own its
// opacity), give it the row's `index`, and handle `swiped`.
//
// A DragHandler rather than a MouseArea over the row: the row is itself a click
// target — close button, action chips, links — and a MouseArea would have to sit
// above it and swallow those clicks, or below it and never see the drag.
// DragHandler only grabs past its threshold, so an ordinary click still lands on
// the content underneath.
Item {
    id: root

    // The row's own index, so the rows around it can be shifted too.
    required property int index

    // How far the finger has to travel before the row is thrown rather than
    // springing back.
    property real swipeThreshold: 72

    // What throwing away means is the caller's: the toast takes the card down
    // and leaves the history entry alone, the centre dismisses the entry.
    signal swiped

    property bool flying: false

    property real flyX: 0.0

    // The dragged row follows the finger exactly.
    readonly property real swipeOffset: {
        if (Core.SwipeState.index < 0)
            return 0;

        const distance = Core.SwipeState.distance;
        const difference = Math.abs(Core.SwipeState.index - root.index);

        if (difference === 0)
            return distance;

        // Once the row is on its way out, the gap closes behind it instead of
        // after it.
        if (Math.abs(distance) > root.swipeThreshold)
            return 0;

        if (difference === 1)
            return distance * 0.3;

        if (difference === 2)
            return distance * 0.1;

        return 0;
    }

    readonly property real offset: root.flying ? root.flyX : root.swipeOffset

    // 1 at rest, falling to 0.3 as the row leaves, so a throw reads as a throw
    // and not as a row that slid under the edge of the card.
    //
    // A property and not `opacity`, so a caller that animates its own opacity —
    // the toast does, on the way in and out — multiplies this in rather than
    // having it overwritten.
    readonly property real travelFade: root.offset === 0
        ? 1.0
        : Math.max(0.3, 1.0 - Math.abs(root.offset) / (root.width * 1.6))

    transform: Translate {
        x: root.offset
    }

    DragHandler {
        target: null

        dragThreshold: 8

        // Horizontal only, and this is what keeps the stack scrollable: Qt
        // refuses to activate a handler with a disabled axis when the drag is
        // mostly along that axis (qquickdraghandler.cpp, "If vertical dragging
        // is disallowed, but the user is dragging mostly vertically, then don't
        // activate"), so a vertical drag starting on a row goes to the
        // Flickable instead of being swallowed here.
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

    // The throw drives `flyX`, a plain property, and `offset` reads it. A
    // NumberAnimation pointed at the Translate breaks the binding behind it for
    // good, and a ListView delegate is recycled: the second row thrown out of
    // the same slot would have had no binding left to follow the finger with, so
    // it would sit still while the stack moved around it. Animating a source
    // property keeps `offset` a binding and the row reusable.
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
            // Hand the offset back to the drag while the row is still marked as
            // flying, or it would animate back in on its way out.
            root.flying = false;
            root.flyX = 0.0;

            Core.SwipeState.release();

            root.swiped();
        }
    }
}
