pragma Singleton

import QtQuick

QtObject {
    id: root

    property int index: -1

    property real distance: 0

    function grab(rowIndex) {
        root.index = rowIndex;
        root.distance = 0;
    }

    function move(delta) {
        root.distance = delta;
    }

    function release() {
        root.index = -1;
        root.distance = 0;
    }
}
