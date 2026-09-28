pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

// Pomodoro.
//
// Stored as a wall-clock instant, never as a countdown that a timer decrements.
// That is the whole reason a reload, a suspend or a shell restart cannot
// desynchronise it: the end of a focus block is an absolute timestamp, so
// catching up is arithmetic rather than bookkeeping.
//
// Persisted through a JSON file in the same idiom as ReminderService, because the
// other option -- a runtime-state object the example config uses -- is 190 lines
// to replace one FileView.

// QtObject, like every other service that owns a Timer: the tick timer is a
// declared property rather than a child, since QtObject has no default
// property to hang one off. ReminderService has done it this way all along.
QtObject {
    id: root

    readonly property string statePath: Core.Paths.shell + "/timer.json"

    // Pomodoro
    //
    // Writable, and clamped on the way in rather than at the call site: the
    // panel writes them with two buttons and the state file is hand-editable, so
    // both paths need the same bounds. 1..120 minutes covers everything anyone
    // actually runs; above that a "pomodoro" is a stopwatch with extra steps.

    property int focusMinutes: 25
    property int breakMinutes: 5
    property int longBreakMinutes: 15
    property int cyclesBeforeLongBreak: 4

    // What the panel offers as one-click shapes. The steppers stay the source of
    // truth -- a preset is four assignments, not a mode -- so touching one value
    // and then picking a preset back is not a fight.
    readonly property var presets: [
        { id: "classic", label: "Classic", focus: 25, brk: 5, lng: 15, cycles: 4 },
        { id: "deep", label: "Deep", focus: 50, brk: 10, lng: 20, cycles: 3 },
        { id: "quick", label: "Quick", focus: 15, brk: 3, lng: 10, cycles: 4 }
    ]

    // The preset the current numbers match, or "custom".
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

        // The bar does not resize as the digits change, and the digits are
        // derived from these, so nothing else has to be told.
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

    // Ticking. `paused` is the third state, and it used not to exist: pause()
    // only stopped the tick, so the countdown kept draining behind the word
    // "Pause" and pressing Start ten minutes later silently threw the rest of
    // the block away.
    property bool running: false

    // Seconds still owed on the current phase while it is frozen. 0 means the
    // phase is live (or has not started), which is why it is the pause flag.
    property int pausedRemaining: 0

    readonly property bool paused: root.pausedRemaining > 0

    // A phase is in progress: counting, or frozen waiting to be resumed. This is
    // what the bar chip shows digits for, and what "skip" acts on.
    readonly property bool live: root.running || root.paused

    property string phase: "focus"
    property int cycle: 0

    // Epoch seconds. 0 means "not started".
    property int endsAt: 0

    // What the current block is for. Purely informational, but it is the part that
    // makes a focus block feel like it has an object.
    property string label: ""

    // Bumped while a block is counting. Reading it inside a binding is what makes
    // that binding re-evaluate: Date.now() on its own has no dependency to
    // invalidate, so a `now` property would freeze at whatever it happened to be
    // when the shell started.
    property int tick: 0

    function now() {
        return Math.floor(Date.now() / 1000);
    }

    readonly property bool isBreak: root.phase !== "focus"

    // Counts finished focus blocks without wrapping, so the fourth one lands on a
    // long break and the eighth on another.
    readonly property bool isLongBreak: root.isBreak && root.cycle % root.cyclesBeforeLongBreak === 0

    readonly property int phaseMinutes: {
        if (root.phase === "focus")
            return root.focusMinutes;

        return root.isLongBreak ? root.longBreakMinutes : root.breakMinutes;
    }

    readonly property int phaseSeconds: root.phaseMinutes * 60

    // Clamped: while a phase is overdue this keeps counting past zero instead of
    // showing a negative clock, and the phase is advanced by the tick. An unset
    // endsAt means "not started yet", which reads as a full phase rather than as
    // an expired one.
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

    // Persistence

    readonly property FileView stateFile: FileView {
        path: root.statePath

        blockLoading: true
        printErrors: false

        // NOT watched, on purpose. This is the file the service writes, so our own
        // write answers back as a change and load() re-reads it -- landing on the
        // value from *before* the write whenever the timing lines up, which put the
        // panel a press behind: the state changed, then snapped back, and the next
        // press "worked" because it read the value the last one had written.
        //
        // Nothing else writes this file. The panel is how the contents change, and
        // a hand edit applies on the next start, which is where `blockLoading` is
        // already earning its keep: the initial read below blocks until there is
        // something to read.
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

        // A live endsAt with a pause remembered is a contradiction; the file is
        // hand-editable and an old version wrote neither field.
        if (root.running)
            root.pausedRemaining = 0;

        // Bounds are re-applied on load for the same reason: the file is text
        // anyone can edit, and a zero-length focus block is a divide by zero
        // three lines below. Assigned rather than routed through setDurations(),
        // which saves -- load() must not write the file it is reading, or the
        // write answers as a change and load() runs again.
        root.focusMinutes = root.clamp(Core.Util.get(state, "focusMinutes", 25), 1, 120, 25);
        root.breakMinutes = root.clamp(Core.Util.get(state, "breakMinutes", 5), 1, 60, 5);
        root.longBreakMinutes = root.clamp(Core.Util.get(state, "longBreakMinutes", 15), 1, 90, 15);
        root.cyclesBeforeLongBreak = root.clamp(Core.Util.get(state, "cyclesBeforeLongBreak", 4), 1, 12, 4);

        // A block that ran out while the shell was not there has to be retired now,
        // or the bar would sit on a finished timer until someone opened the panel.
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

    // Pomodoro

    function start() {
        // Resuming a pause re-arms the absolute end from what was left. This has
        // to be a new end rather than the old one: pause() moved the remainder
        // into `pausedRemaining` and cleared `endsAt`, so a resume that trusted
        // `endsAt` would come back to a phase with no end at all -- a full block
        // that the tick then completed on its first pass.
        if (root.paused) {
            root.endsAt = root.now() + root.pausedRemaining;
        } else if (root.endsAt <= root.now()) {
            // A phase that ran out while paused -- or while the shell was not
            // there -- restarts from the top rather than jumping to the next
            // one, which would skip a break entirely.
            root.endsAt = root.now() + root.phaseSeconds;
        }

        root.pausedRemaining = 0;
        root.running = true;

        root.save();
    }

    // Freezes the block where it stands: the seconds still owed move into
    // `pausedRemaining` and the absolute end goes away, so nothing drains while
    // the word "Paused" is on screen.
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

    // The right button: end this block now and count the next one, without
    // waiting out the clock.
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

    // Called by the tick, and once on load.
    function advance() {
        if (root.endsAt > root.now())
            return false;

        // A phase that ran out while the machine was asleep is simply over: the
        // next one starts now rather than being replayed in arrears.
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

    // The panel is not necessarily open and the bar is hidden, so the phase change
    // is announced by the same daemon that serves everything else.
    function announce() {
        const text = root.phase === "focus" ? "Focus" : root.phaseLabel;

        Quickshell.execDetached(["notify-send", "-a", "Shell", "Pomodoro", text + " for " + root.phaseMinutes + " min"]);
    }

    // Half a second, because the panel shows seconds and a countdown that skips
    // visibly is worse than one that costs a timer. The tick is also what notices
    // a block running out, so it stops the moment nothing is counting.
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

        // Catches a block that expired between the file being read and this shell
        // starting, without a tick having to fire first.
        if (root.running)
            root.advance();
    }
}
