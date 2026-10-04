pragma Singleton

import QtQuick

QtObject {
    id: root

    property string kind: ""

    readonly property bool active: root.kind !== ""

    readonly property int holdDuration: 1600

    property bool armed: false

    property Timer armTimer: Timer {
        interval: 1500

        running: true
        repeat: false

        onTriggered: root.armed = true
    }

    property Timer hideTimer: Timer {
        interval: root.holdDuration

        repeat: false

        onTriggered: root.kind = ""
    }

    function show(kind) {
        if (!root.armed)
            return;

        root.kind = kind;
        root.hideTimer.restart();
    }
}
