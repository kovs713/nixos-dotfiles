pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

import "../core" as Core

// BrightnessService

Singleton {
    id: root

    // 0..100.
    property int level: 0

    readonly property real fraction: root.level / 100

    // False until a reading actually succeeds, so a desktop with no backlight can be detected rather than showing a fake 0%.
    property bool available: false

    readonly property int stepSize: 5

    // Discovered hardware

    // e.g. "amdgpu_bl1" or "intel_backlight".
    property string device: ""

    // Raw scale maximum, NOT a percentage.
    property int maxRaw: 0

    property int probeTries: 0

    // A local change updates the number instantly and briefly suppresses readings, so a poll landing mid-write cannot snap the value back and
    property double ignoreReadsUntil: 0

    // Single entry point for every reading

    function ingest(percent) {
        if (percent < 0)
            return;
        root.available = true;

        if (Date.now() < root.ignoreReadsUntil)
            return;
        const value = Math.max(0, Math.min(100, Math.round(percent)));

        // Only assign on a real change.
        if (value !== root.level) {
            root.level = value;

            // Something moved the backlight, so poll fast for a moment in case
            // this is the start of a burst (a held brightness key).
            root.markInteraction();
        }
    }

    // One-shot discovery

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

                // Seed the value immediately so the bar is correct on the very first frame, before the first file read lands.
                root.ingest(parseInt(String(fields[3]).replace("%", "")));
            }
        }
    }

    function runProbe() {
        root.probeTries += 1;
        Core.Util.restart(root.probe);
    }

    // The cheap reading path

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

    // The file speaks raw units; brightnessctl -- which wrote the last value,
    // and whose `5%+` steps everything here makes -- speaks this one.
    //
    // brightnessctl's scale is `raw = max * (percent/100)^4` (its -e, default 4:
    // "the exponential curve may make the adjustments perceptually equal"), so
    // the number it prints is 100 * (raw/max)^(1/4). Reading raw/max instead put
    // a linear number on the bar next to a perceptual step: one key press was
    // worth 5 points at the bottom of the range and 19 at the top, so a held key
    // read as the value lurching. The probe above already passed the
    // percentage, and the two disagreed by exactly this curve.
    function percentOf(raw) {
        return Math.pow(raw / root.maxRaw, 0.25) * 100;
    }

    // Actions

    function change(amount) {
        Quickshell.execDetached(["brightnessctl", "-e4", "-n2", "set", amount]);
    }

    // Predict so the click feels instant, then let the file read settle the true value.
    function applyPredicted(next) {
        const clamped = Math.max(0, Math.min(100, Math.round(next)));

        root.ignoreReadsUntil = Date.now() + 120;

        // A local change is interaction by definition.
        root.markInteraction();

        if (clamped !== root.level) {
            root.level = clamped;
        } else {
            // Already at the rail, so onLevelChanged will not fire.
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

    // OSD trigger. No value: BarOsd reads `fraction` live, so there is no
    // number to read here and no chance of reading the previous one -- see
    // OsdController.
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
        // A held key is a write every 40ms (input.repeat_rate), so 100ms could
        // only ever show every third step of it. 25ms reads the whole burst; the
        // file is a dozen bytes, and this only runs while something is moving.
        interval: root.interacting ? 25 : 400

        running: root.device !== ""
        repeat: true

        onTriggered: root.backlightFile.reload()
    }

    // Only runs until the device is found, and gives up rather than spawning brightnessctl forever on a machine that has no backlight at all.
    readonly property Timer discoveryRetry: Timer {
        interval: 1000

        running: root.device === "" && root.probeTries < 5

        repeat: true

        onTriggered: root.runProbe()
    }


    Component.onCompleted: root.runProbe()
}
