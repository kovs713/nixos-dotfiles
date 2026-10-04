pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

QtObject {
    id: root

    readonly property int neutral: 6500

    readonly property int warm: 3000

    property int temperature: root.neutral

    readonly property bool active: root.temperature !== root.neutral

    readonly property string statePath: Core.Paths.shell + "/nightlight"

    readonly property var stateFile: FileView {
        path: root.statePath

        watchChanges: true

        blockLoading: true

        printErrors: false

        onFileChanged: root.ingest()
    }

    readonly property string socketPath: Core.Paths.runtime
        + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.hyprsunset.sock"

    readonly property string command: root.temperature === root.neutral
        ? "identity"
        : "temperature " + root.temperature

    readonly property Process client: Process {
        command: ["sh", "-c", "printf '%s\\n' \"" + root.command + "\" | timeout 1 nc -U " + root.socketPath]

        stdout: StdioCollector {
            onStreamFinished: {
                const reply = text.trim();

                if (reply !== "ok")
                    console.warn("NightLightService: hyprsunset answered '" + reply + "'");
            }
        }
    }

    function ingest() {
        const value = parseInt(String(root.stateFile.text()).trim(), 10);

        if (isNaN(value) || value < 1000 || value > 10000)
            return;

        if (root.wrote) {
            root.wrote = false;
            return;
        }

        root.temperature = value;
    }

    function persist() {
        root.wrote = true;
        root.stateFile.setText(String(root.temperature));
    }

    property bool wrote: false

    function apply() {
        Core.Util.restart(root.client);
    }

    function setTemperature(value) {
        root.temperature = Math.max(1000, Math.min(10000, Math.round(value)));
        root.apply();
        root.persist();
    }

    function toggle() {
        root.setTemperature(root.active ? root.neutral : root.warm);
    }

    function step(delta) {
        root.setTemperature(root.temperature - delta * 250);
    }

    Component.onCompleted: {
        root.ingest();

        root.apply();
    }
}
