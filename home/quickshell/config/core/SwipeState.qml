pragma Singleton

import QtQuick

// Which row is currently being dragged sideways, and how far.
//
// A singleton rather than a property on the ListView because the effect is not
// local to the dragged row: the rows above and below it shift too, in a decaying
// ratio, and a delegate cannot see its siblings without a shared place to ask.
// 1.0 / 0.3 / 0.1 is what makes the stack feel like it is made of cards instead
// of independent rectangles.
QtObject {
    id: root

    // -1 when nothing is being dragged.
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
