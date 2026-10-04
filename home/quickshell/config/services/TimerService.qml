pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

QtObject {
    id: root

    readonly property string statePath: Core.Paths.shell + "/timer.json"

    property int focusMinutes: 25
    property int breakMinutes: 5
    property int longBreakMinutes: 15
    property int cyclesBeforeLongBreak: 4

    readonly property var presets: [
        { id: "classic", label: "Classic", focus: 25, brk: 5, lng: 15, cycles: 4 },
        { id: "deep", label: "Deep", focus: 50, brk: 10, lng: 20, cycles: 3 },
        { id: "quick", label: "Quick", focus: 15, brk: 3, lng: 10, cycles: 4 }
    ]

    readonly property string presetId: {
        for (let i = 0; i < root.presets.length; i++) {
            const p = root.presets[i];

            if (p.focus === root.focusMinutes && p.brk === root.breakMinutes
                && p.lng === root.longBreakMinutes && p.cycles === root.cyclesBeforeLongBreak)
                return p.id;
        }

        return "custom";
    }

    function setFocusMinutes(value) {
        root.setDurations(value, root.breakMinutes, root.longBreakMinutes, root.cyclesBeforeLongBreak);
    }

    function setBreakMinutes(value) {
        root.setDurations(root.focusMinutes, value, root.longBreakMinutes, root.cyclesBeforeLongBreak);
    }

    function setLongBreakMinutes(value) {
        root.setDurations(root.focusMinutes, root.breakMinutes, value, root.cyclesBeforeLongBreak);
    }

    function setCycles(value) {
        root.setDurations(root.focusMinutes, root.breakMinutes, root.longBreakMinutes, value);
    }

    function setDurations(focus, brk, lng, cycles) {
        root.focusMinutes = clamp(focus, 1, 120, 25);
        root.breakMinutes = clamp(brk, 1, 60, 5);
        root.longBreakMinutes = clamp(lng, 1, 90, 15);
        root.cyclesBeforeLongBreak = clamp(cycles, 1, 12, 4);

        root.save();
    }

    function applyPreset(id) {
        for (let i = 0; i < root.presets.length; i++) {
            const p = root.presets[i];

            if (p.id === id) {
                root.setDurations(p.focus, p.brk, p.lng, p.cycles);
                return;
            }
        }
    }

    function clamp(value, min, max, fallback) {
        const n = Math.round(Number(value));

        if (!isFinite(n))
            return fallback;

        return Math.max(min, Math.min(max, n));
    }

    property bool running: false

    property int pausedRemaining: 0

    readonly property bool paused: root.pausedRemaining > 0

    readonly property bool live: root.running || root.paused

    property string phase: "focus"
    property int cycle: 0

    property int endsAt: 0

    property string label: ""

    property int tick: 0

    function now() {
        return Math.floor(Date.now() / 1000);
    }

    readonly property bool isBreak: root.phase !== "focus"

    readonly property bool isLongBreak: root.isBreak && root.cycle % root.cyclesBeforeLongBreak === 0

    readonly property int phaseMinutes: {
        if (root.phase === "focus")
            return root.focusMinutes;

        return root.isLongBreak ? root.longBreakMinutes : root.breakMinutes;
    }

    readonly property int phaseSeconds: root.phaseMinutes * 60

    readonly property int secondsLeft: {
        root.tick;

        if (root.paused)
            return root.pausedRemaining;

        if (root.endsAt === 0)
            return root.phaseSeconds;

        return Math.max(0, root.endsAt - root.now());
    }

    readonly property real progress: root.phaseSeconds > 0 ? Math.max(0, Math.min(1, root.secondsLeft / root.phaseSeconds)) : 0

    readonly property string phaseLabel: {
        if (root.phase === "focus")
            return "Focus";

        return root.isLongBreak ? "Long break" : "Break";
    }

    readonly property FileView stateFile: FileView {
        path: root.statePath

        blockLoading: true
        printErrors: false

        watchChanges: false
    }

    function load() {
        const raw = root.stateFile.text();

        if (!raw) {
            root.running = false;

            return;
        }

        let state;

        try {
            state = JSON.parse(raw);
        } catch (e) {
            return;
        }

        if (!state)
            return;

        root.phase = state.phase === "break" ? "break" : "focus";
        root.cycle = Number(state.cycle) || 0;
        root.endsAt = Number(state.endsAt) || 0;
        root.label = typeof state.label === "string" ? state.label : "";
        root.running = state.running === true;
        root.pausedRemaining = Math.max(0, Number(state.pausedRemaining) || 0);

        if (root.running)
            root.pausedRemaining = 0;

        root.focusMinutes = root.clamp(Core.Util.get(state, "focusMinutes", 25), 1, 120, 25);
        root.breakMinutes = root.clamp(Core.Util.get(state, "breakMinutes", 5), 1, 60, 5);
        root.longBreakMinutes = root.clamp(Core.Util.get(state, "longBreakMinutes", 15), 1, 90, 15);
        root.cyclesBeforeLongBreak = root.clamp(Core.Util.get(state, "cyclesBeforeLongBreak", 4), 1, 12, 4);

        if (root.running)
            root.advance();
    }

    function save() {
        root.stateFile.setText(JSON.stringify({
            running: root.running,
            phase: root.phase,
            cycle: root.cycle,
            endsAt: root.endsAt,
            label: root.label,
            pausedRemaining: root.pausedRemaining,
            focusMinutes: root.focusMinutes,
            breakMinutes: root.breakMinutes,
            longBreakMinutes: root.longBreakMinutes,
            cyclesBeforeLongBreak: root.cyclesBeforeLongBreak
        }));
    }

    function start() {
        if (root.paused) {
            root.endsAt = root.now() + root.pausedRemaining;
        } else if (root.endsAt <= root.now()) {
            root.endsAt = root.now() + root.phaseSeconds;
        }

        root.pausedRemaining = 0;
        root.running = true;

        root.save();
    }

    function pause() {
        if (!root.running)
            return;

        root.pausedRemaining = Math.max(0, root.endsAt - root.now());
        root.endsAt = 0;
        root.running = false;

        root.save();
    }

    function toggle() {
        if (root.running)
            root.pause();
        else
            root.start();
    }

    function skip() {
        if (!root.live)
            return;

        root.pausedRemaining = 0;
        root.endsAt = root.now() - 1;

        root.advance();
    }

    function reset() {
        root.running = false;
        root.pausedRemaining = 0;
        root.endsAt = 0;
        root.cycle = 0;
        root.phase = "focus";

        root.save();
    }

    function advance() {
        if (root.endsAt > root.now())
            return false;

        if (root.phase === "focus") {
            root.cycle = root.cycle + 1;
            root.phase = "break";
        } else {
            root.phase = "focus";
        }

        root.endsAt = root.now() + root.phaseSeconds;
        root.pausedRemaining = 0;

        root.announce();

        root.save();

        return true;
    }

    function announce() {
        const text = root.phase === "focus" ? "Focus" : root.phaseLabel;

        Quickshell.execDetached(["notify-send", "-a", "Shell", "Pomodoro", text + " for " + root.phaseMinutes + " min"]);
    }

    readonly property Timer tickTimer: Timer {
        interval: 500
        repeat: true

        running: root.running

        onTriggered: {
            root.tick++;

            if (root.running)
                root.advance();
        }
    }

    function formatSeconds(total) {
        const seconds = Math.max(0, Math.floor(total));

        const minutes = Math.floor(seconds / 60);
        const rest = seconds % 60;

        return minutes + ":" + (rest < 10 ? "0" : "") + rest;
    }

    Component.onCompleted: {
        root.load();

        if (root.running)
            root.advance();
    }
}
