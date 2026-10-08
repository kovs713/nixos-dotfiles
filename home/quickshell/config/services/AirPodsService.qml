pragma Singleton

import QtQuick

import Quickshell.Io

import "../core" as Core
import "../core/AirPods.js" as AirPods

QtObject {
    id: root

    // Written only when the status changes, and removed when the daemon stops, so
    // there is nothing to poll: an absent file is a stopped daemon.
    readonly property string statePath: Core.Paths.state + "/librepods/status.json"

    // The daemon says which of these the hardware has: an AirPods 3 has no
    // listening modes, and a Max has no case and no One-Bud ANC.
    property bool supportsNoiseOff: true
    property bool supportsNoiseControl: true
    property bool supportsAdaptive: false
    property bool supportsConversationalAwareness: false
    property bool supportsOneBudANC: false

    // Held over incoming reads until the daemon agrees, so a write already in flight
    // when the click landed cannot snap the control back.
    property string pendingField: ""
    property var pendingValue: null

    // Single slot: a verb sent while another is in flight replaces the queued one
    // rather than being dropped, which is what a wheel repeat produces.
    property var queued: null

    property bool running: false
    property bool connected: false
    property string deviceName: ""
    property string modelName: ""
    property bool isHeadset: false
    property int noiseMode: AirPods.NOISE_UNKNOWN
    property int adaptiveNoiseLevel: 0
    property bool oneBudANC: false
    property bool conversationalAwareness: false
    property int earDetectionBehavior: AirPods.EAR_PAUSE_ONE_OUT
    property int lidState: AirPods.LID_UNKNOWN
    property var left: AirPods.defaultPod()
    property var right: AirPods.defaultPod()
    property var caseBattery: AirPods.defaultPod()
    property var headset: AirPods.defaultPod()

    readonly property int lowestLevel: AirPods.lowestLevel(root)

    readonly property var modes: AirPods.availableModes(root.supportsNoiseControl, root.supportsNoiseOff, root.supportsAdaptive)

    property string error: ""

    property string notice: ""

    readonly property bool busy: ctlProcess.running

    readonly property var stateFile: FileView {
        path: root.statePath

        watchChanges: true

        printErrors: false

        // text() is stale inside the change signal, so both paths go through reload.
        onFileChanged: reload()

        onLoaded: root.applyLine(text())

        onLoadFailed: root.stateGone()
    }

    readonly property Process ctlProcess: Process {
        running: false
        command: []
        stderr: StdioCollector {
            id: ctlErr
            waitForEnd: true
        }
        onExited: function (exitCode) {
            if (exitCode !== 0) {
                // Clearing the hold also stops the timer that would have re-read, so do it here.
                root.clearPending();
                root.refresh();
                root.queued = null;
                root.notice = AirPods.elideError(ctlErr.text);
                noticeTimer.restart();
            }

            if (root.queued) {
                const next = root.queued;

                root.queued = null;
                root.send(next.verb, next.field, next.value);
            }
        }
    }

    readonly property Timer settleTimer: Timer {
        // Bounds the hold and re-reads: a verb the pods ignored changes nothing, so
        // the daemon writes no line and no watch fires.
        interval: 4000
        repeat: false
        onTriggered: {
            root.clearPending();
            root.refresh();
        }
    }

    readonly property Timer noticeTimer: Timer {
        interval: 2600
        repeat: false
        onTriggered: root.notice = ""
    }

    function applyLine(raw) {
        const status = AirPods.parseStatus(raw);

        if (!status.ok) {
            // A line we cannot read still proves the daemon is running and writing.
            root.running = true;
            root.connected = false;
            root.error = status.error;
            return;
        }

        root.running = true;
        root.error = status.error;

        root.connected = status.connected;
        root.deviceName = status.deviceName;
        root.modelName = status.modelName;
        root.isHeadset = status.isHeadset;
        root.supportsNoiseOff = status.supportsNoiseOff;
        root.supportsNoiseControl = status.supportsNoiseControl;
        root.supportsAdaptive = status.supportsAdaptive;
        root.supportsConversationalAwareness = status.supportsConversationalAwareness;
        root.supportsOneBudANC = status.supportsOneBudANC;
        root.left = status.left;
        root.right = status.right;
        root.caseBattery = status.caseBattery;
        root.headset = status.headset;
        root.lidState = status.lidState;

        root.noiseMode = settle("noiseMode", status.noiseMode);
        root.adaptiveNoiseLevel = settle("adaptiveNoiseLevel", status.adaptiveNoiseLevel);
        root.oneBudANC = settle("oneBudANC", status.oneBudANC);
        root.conversationalAwareness = settle("conversationalAwareness", status.conversationalAwareness);
        root.earDetectionBehavior = settle("earDetectionBehavior", status.earDetectionBehavior);
    }

    function stateGone() {
        root.running = false;
        root.connected = false;
        root.error = "";
    }

    function refresh() {
        root.stateFile.reload();
    }

    function settle(field, reported) {
        if (root.pendingField !== field)
            return reported;

        if (reported === root.pendingValue) {
            root.clearPending();
            return reported;
        }

        return root.pendingValue;
    }

    function clearPending() {
        root.pendingField = "";
        root.pendingValue = null;
        root.settleTimer.stop();
    }

    function send(verb, field, value) {
        if (verb === "")
            return;

        if (root.busy) {
            root.queued = { verb: verb, field: field, value: value };
            hold(field, value);
            return;
        }

        hold(field, value);
        root.ctlProcess.command = [ "librepods-ctl", verb ];
        root.ctlProcess.running = true;
    }

    function hold(field, value) {
        root.pendingField = field;
        root.pendingValue = value;
        root[field] = value;
        root.settleTimer.restart();
    }

    function setNoiseMode(mode) {
        if (root.modes.indexOf(mode) < 0)
            return;

        root.send(AirPods.noiseModeVerb(mode), "noiseMode", mode);
    }

    function cycleNoiseMode() {
        if (!root.connected || root.modes.length === 0)
            return;

        const at = root.modes.indexOf(root.noiseMode);

        // An unknown current mode has no next one, so start at the head rather than past it.
        root.setNoiseMode(at < 0 ? root.modes[0] : root.modes[(at + 1) % root.modes.length]);
    }

    function setAdaptiveNoiseLevel(level) {
        const clamped = Math.max(0, Math.min(100, Math.round(level)));

        root.send("adaptive:" + clamped, "adaptiveNoiseLevel", clamped);
    }

    function setConversationalAwareness(enabled) {
        root.send(enabled ? "ca:on" : "ca:off", "conversationalAwareness", enabled);
    }

    function setOneBudANC(enabled) {
        root.send(enabled ? "onebud:on" : "onebud:off", "oneBudANC", enabled);
    }

    function setEarDetection(behavior) {
        root.send(AirPods.earDetectionVerb(behavior), "earDetectionBehavior", behavior);
    }

    function cycleEarDetection() {
        root.setEarDetection((root.earDetectionBehavior + 1) % AirPods.EAR_BEHAVIOR_COUNT);
    }
}