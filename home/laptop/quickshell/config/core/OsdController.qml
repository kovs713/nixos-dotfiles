pragma Singleton

import QtQuick

// OsdController
//
// Which readout, and for how long. Deliberately NOT its value.
//
// A caller used to hand the number in: `show(kind, value, muted)`, and the
// caller was always a change handler, because that is what decides to raise an
// OSD. So the value had to be read inside `onSomethingChanged` -- and reading a
// property that is itself a binding on the one that just changed reads the
// PREVIOUS value, because QML re-evaluates dependent bindings after the
// handler. Every step of a held brightness key was therefore announced one step
// late, and a step onto a rail was never announced at all: 95 became 100, the
// value stopped moving, and the readout sat on 95 until something else woke it.
// The view now reads the live property instead, so a number pushed across this
// seam cannot be stale, and a new caller cannot get it wrong.
//
// The number of a rail being invisible was the second half of that bug: with
// the value live, holding the key at 100% keeps the OSD up and keeps saying
// 100%, which is the truth, instead of the UI going quiet for the rest of the
// hold.

QtObject {
    id: root

    property string kind: ""

    readonly property bool active: root.kind !== ""

    // How long the readout stays up after the last change.
    readonly property int holdDuration: 1600

    // Startup guard

    property bool armed: false

    property Timer armTimer: Timer {
        interval: 1500

        running: true
        repeat: false

        onTriggered: root.armed = true
    }

    // Hold timer

    property Timer hideTimer: Timer {
        interval: root.holdDuration

        repeat: false

        onTriggered: root.kind = ""
    }

    // API

    // Raise (or refresh) an OSD. The view resolves `kind` to a live value.
    function show(kind) {
        if (!root.armed)
            return;

        root.kind = kind;
        root.hideTimer.restart();
    }
}
