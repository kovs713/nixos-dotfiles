pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

// Screen colour temperature.
//
// The backend is hyprsunset, and it is not the obvious one. gammastep and sct
// both speak routes Hyprland refuses here: sct writes the gamma ramp through
// DRM, Hyprland holds DRM master, and the write is rejected -- sct still prints
// "Temperature: 3000K" when it does this, because it reports the temperature it
// was asked for rather than one that landed. gammastep talks
// `zwlr_gamma_control_manager_v1` properly, binds it, and gets `failed()` back
// for this output:
//
//     -> zwlr_gamma_control_manager_v1.get_gamma_control(new id ..., wl_output#5)
//     zwlr_gamma_control_v1#3.failed()
//     Warning: Zero outputs support gamma adjustment.
//
// so it exits non-zero having changed nothing. Hyprland also exports a
// colour-temperature protocol of its own, `hyprland_ctm_control_manager_v1`,
// which does work, and hyprsunset prefers it: the temperature lands as a CTM on
// the output rather than as a gamma ramp.
//
// hyprsunset is a daemon, not a command: it holds the CTM protocol open, and the
// temperature is gone the moment it is not. But it is also a *server* -- it
// listens on one unix socket per Hyprland instance, and answers three commands
// on it, each with "ok":
//
//     temperature <kelvin>     the ramp
//     identity                 no ramp, i.e. what the compositor does by itself
//     gamma <percent>          separate knob, unused here
//
// Anything else gets "invalid command". So this file is a client: one
// `printf | nc -U` per change, which exits immediately and holds nothing. It
// used to own the daemon instead, and every bug here came from that -- a
// resident process cannot be replaced in place, because the replacement starts
// while the previous one still holds the protocol and exits having applied
// nothing; a leftover from a shell that was killed rather than closed kept the
// compositor-wide manager, so no new daemon could take it at all and the toggle
// did nothing; and clearing that field needed a pkill before every start.
//
// The daemon is hyprsunset's own systemd user unit, enabled in default.nix, and
// not this file: it is compositor state, it outlives the shell, and there can be
// exactly one of it. It comes up at hyprsunset's own default and this file
// overwrites that on the way up, always, because "off" is a command too and the
// shell is the only thing that knows which of the two the session wants.
//
// The temperature itself is not read back, because nothing on this machine can
// read a CTM back. The reply is, so a change that did not land says so.


QtObject {
    id: root

    readonly property int neutral: 6500

    // The one temperature the toggle turns on. A slider is the wrong control
    // here: almost every session wants "normal" or "warm at night", and a
    // control that can be left anywhere in between is a control that has to be
    // reasoned about. The wheel is still there for the nights that want finer,
    // and it writes the same state, so the toggle picks up whatever it left.
    readonly property int warm: 3000

    property int temperature: root.neutral

    readonly property bool active: root.temperature !== root.neutral

    // ~/.config/shell, not XDG_STATE_HOME: that is where the timer, the
    // reminders and the notes already keep their state, and it is the only one
    // of the two that something guarantees to exist. XDG_STATE_HOME/shell is
    // created by nothing, and FileView.write does not mkdir, so a path there
    // fails silently and the temperature is lost on every restart.
    readonly property string statePath: Core.Paths.shell + "/nightlight"

    readonly property var stateFile: FileView {
        path: root.statePath

        watchChanges: true

        blockLoading: true

        printErrors: false

        onFileChanged: root.ingest()
    }

    // The control socket, one per Hyprland instance. hyprsunset builds the path
    // out of the same two variables, so this is the path and not a search for
    // it, and both are in the systemd user manager's environment -- which is
    // also what lets the daemon unit below find the compositor.
    readonly property string socketPath: Core.Paths.runtime
        + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.hyprsunset.sock"

    // What to ask for. "Off" is `identity` and not a temperature: the compositor
    // applies the identity ramp itself when nothing is holding a CTM, so a
    // neutral temperature would be a second way for the two to disagree.
    readonly property string command: root.temperature === root.neutral
        ? "identity"
        : "temperature " + root.temperature

    // One short-lived client per change, and it says whether the change landed.
    // The sh is here to pipe, not to interpret: the command is a literal or a
    // clamped integer out of root.temperature, so there is nothing in it to
    // quote around.
    //
    // `timeout` because nc does not exit by itself: it waits for EOF on stdin
    // and then for the far end to close, and hyprsunset closes neither -- the
    // write end is this Process, which stays open. So the client would sit there
    // until the next change killed it, which is a process per press. The
    // command itself lands in the first millisecond, so one second is a
    // lifetime, not a deadline.
    readonly property Process client: Process {
        command: ["sh", "-c", "printf '%s\\n' \"" + root.command + "\" | timeout 1 nc -U " + root.socketPath]

        stdout: StdioCollector {
            onStreamFinished: {
                const reply = text.trim();

                // "ok", or "invalid command" from a daemon that disagrees about
                // its own protocol. Either way the log is the only place the
                // answer can go, because the temperature cannot be read back.
                if (reply !== "ok")
                    console.warn("NightLightService: hyprsunset answered '" + reply + "'");
            }
        }
    }

    function ingest() {
        const value = parseInt(String(root.stateFile.text()).trim(), 10);

        if (isNaN(value) || value < 1000 || value > 10000)
            return;

        // Our own write, coming back through the watch. The FileView watches the
        // file that persist() writes to, so the write answers as a change and
        // this read lands on the value from *before* it -- the temperature
        // reverting a step behind the press, then a step behind the next one.
        // One write, one notification, so one skip is enough.
        if (root.wrote) {
            root.wrote = false;
            return;
        }

        root.temperature = value;
    }

    function persist() {
        // setText, not `text =` + write(): text is read-only on FileView in 0.3.0
        // and assigning to it throws a TypeError that swallows the write. Same
        // call TimerService and ReminderService use.
        root.wrote = true;
        root.stateFile.setText(String(root.temperature));
    }

    // Cleared by the notification persist() provokes, and set again by the next
    // write. A write the file answers with nothing costs one flag, not a state
    // that never comes back.
    property bool wrote: false

    function apply() {
        // A client is not state, so there is nothing to tear down and nothing to
        // race: the previous one either answered or is about to, and the
        // temperature it was carrying has been replaced anyway.
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
        // The initial read has to be asked for. `fileChanged` answers a change
        // on disk, not the read the FileView does on its own, so without this
        // line the saved temperature is never restored and the shell comes up
        // neutral whatever the file says. TimerService and ReminderService load
        // here for the same reason.
        root.ingest();

        // Always, not only when the file has a temperature: the daemon comes up
        // at its own default and holds a ramp from the moment it binds, and the
        // CTM does not survive a reboot or a compositor restart either. So this
        // is the shell asserting the state, and `identity` is what it asserts
        // when the file says off.
        root.apply();
    }
}
