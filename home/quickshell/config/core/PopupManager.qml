pragma Singleton

import QtQuick

// PopupManager
//
// The open protocol for bar popups. A bar module says *which* popup and *which
// item it is*, and the anchor arithmetic happens here.
//
// It used to be the other way round: every bar module called
// `mapToItem(null, 0, height)` itself and passed two screen coordinates. The
// second one was never read by anything, so it was free to drift — Battery.qml
// passed a bare `6` where the other six passed Theme.barMarginTop, and nobody
// could tell, because the value was discarded.

QtObject {
    id: root

    // Currently open popup id ("" == nothing open)
    property string current: ""

    // The bar module that opened it. Held so the anchor can be derived rather
    // than supplied.
    property Item anchorItem: null

    // Screen-space horizontal centre of the anchor, clamped by the popup.
    readonly property real anchorCenter: {
        if (!root.anchorItem)
            return 0;

        const p = root.anchorItem.mapToItem(null, root.anchorItem.width / 2, 0);

        return p.x;
    }

    function isOpen(id) {
        return root.current === id;
    }

    function open(id, sourceItem) {
        root.anchorItem = sourceItem;
        root.current = id;
    }

    function toggle(id, sourceItem) {
        if (root.current === id) {
            root.close();
            return;
        }

        root.open(id, sourceItem);
    }

    function close() {
        root.anchorItem = null;
        root.current = "";
    }
}
