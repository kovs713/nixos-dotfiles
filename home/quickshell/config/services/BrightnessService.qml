pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

import "../core" as Core

// One source of truth for brightness on both hosts: `backlight` reads a sysfs
// backlight on the laptop and drives the monitor over DDC on the desktop, and
// prints a plain percent either way. So nothing here detects devices or knows
// about sysfs -- it reads a number, predicts the next one, and asks for the step.
//
// Reads cost a DDC roundtrip on the desktop, so they are a plain poll and the
// level shown right after a press is a prediction. The poll is what makes it
// converge; the short quiet window after a press is what stops a read that
// caught the monitor mid-write from bouncing the OSD backwards.
Singleton {
    id: root

    property int level: 0

    readonly property real fraction: root.level / 100

    property bool available: false

    readonly property int stepSize: 5

    property double ignoreReadsUntil: 0

    function ingest(percent) {
        if (isNaN(percent) || percent < 0)
            return;

        root.available = true;

        if (Date.now() < root.ignoreReadsUntil)
            return;

        const value = Math.max(0, Math.min(100, Math.round(percent)));

        if (value !== root.level)
            root.level = value;
    }

    readonly property Process probe: Process {
        command: ["backlight", "get"]

        stdout: StdioCollector {
            onStreamFinished: root.ingest(parseInt(text.trim()))
        }
    }

    function refresh() {
        Core.Util.restart(root.probe);
    }

    function step(up) {
        const next = Math.max(0, Math.min(100, root.level + (up ? root.stepSize : -root.stepSize)));

        // At an end of the range there is no write to wait for, so the OSD still
        // has to show the press happened.
        if (next === root.level) {
            Core.OsdController.show("brightness");
            return;
        }

        root.ignoreReadsUntil = Date.now() + 150;
        root.level = next;

        Quickshell.execDetached(["backlight", up ? "up" : "down"]);
    }

    onLevelChanged: Core.OsdController.show("brightness")

    readonly property Timer poll: Timer {
        interval: 1000

        running: true

        repeat: true

        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}