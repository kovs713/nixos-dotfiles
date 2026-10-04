pragma Singleton

import QtQuick

QtObject {
    id: root

    property string current: ""

    property Item anchorItem: null

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
