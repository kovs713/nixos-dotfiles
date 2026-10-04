pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

import "../core" as Core

Singleton {
    id: root

    property int level: 0

    readonly property real fraction: root.level / 100

    property bool available: false

    readonly property int stepSize: 5

    property string device: ""

    property int maxRaw: 0

    property int probeTries: 0

    property double ignoreReadsUntil: 0

    function ingest(percent) {
        if (isNaN(percent) || percent < 0)
            return;
        root.available = true;

        if (Date.now() < root.ignoreReadsUntil)
            return;
        const value = Math.max(0, Math.min(100, Math.round(percent)));

        if (value !== root.level) {
            root.level = value;

            root.markInteraction();
        }
    }

    readonly property Process probe: Process {
        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0];

                if (!line)
                    return;
                const fields = line.split(",");

                if (fields.length < 5)
                    return;
                const max = parseInt(fields[4]);

                if (isNaN(max) || max <= 0)
                    return;
                root.device = fields[0];
                root.maxRaw = max;

                root.ingest(parseInt(String(fields[3]).replace("%", "")));
            }
        }
    }

    function runProbe() {
        root.probeTries += 1;
        Core.Util.restart(root.probe);
    }

    readonly property FileView backlightFile: FileView {
        path: root.device === "" ? "" : "/sys/class/backlight/" + root.device + "/actual_brightness"

        onLoaded: {
            if (root.maxRaw <= 0)
                return;
            const raw = parseInt(root.backlightFile.text().trim());

            if (isNaN(raw))
                return;
            root.ingest(root.percentOf(raw));
        }
    }

    function percentOf(raw) {
        return Math.pow(raw / root.maxRaw, 0.25) * 100;
    }

    readonly property Process ddc: Process {
        command: ["backlight", "get"]

        stdout: StdioCollector {
            onStreamFinished: root.ingest(parseInt(text.trim()))
        }
    }

    function change(amount) {
        if (root.device === "")
            Quickshell.execDetached(["backlight", amount > 0 ? "up" : "down"]);
        else
            Quickshell.execDetached(["brightnessctl", "-e4", "-n2", "set", amount]);
    }

    function applyPredicted(next) {
        const clamped = Math.max(0, Math.min(100, Math.round(next)));

        root.ignoreReadsUntil = Date.now() + 120;

        root.markInteraction();

        if (clamped !== root.level) {
            root.level = clamped;
        } else {
            Core.OsdController.show("brightness");
        }
    }

    function step(up) {
        root.applyPredicted(root.level + (up ? root.stepSize : -root.stepSize));

        root.change(up ? root.stepSize + "%+" : root.stepSize + "%-");
    }

    function refresh() {
        if (root.device === "")
            root.runProbe();
        else
            root.backlightFile.reload();
    }

    onLevelChanged: Core.OsdController.show("brightness")

    property bool interacting: false

    function markInteraction() {
        root.interacting = true;
        root.interactionCooldown.restart();
    }

    readonly property Timer interactionCooldown: Timer {
        interval: 2500

        repeat: false

        onTriggered: root.interacting = false
    }

    readonly property Timer poll: Timer {
        // DDC reads cost an i2c roundtrip, the sysfs file is free.
        interval: root.device === "" ? 1000 : root.interacting ? 25 : 400

        running: root.device !== "" || root.probeTries >= 5
        repeat: true

        onTriggered: {
            if (root.device === "")
                Core.Util.restart(root.ddc);
            else
                root.backlightFile.reload();
        }
    }

    readonly property Timer discoveryRetry: Timer {
        interval: 1000

        running: root.device === "" && root.probeTries < 5

        repeat: true

        onTriggered: root.runProbe()
    }

    Component.onCompleted: root.runProbe()
}
