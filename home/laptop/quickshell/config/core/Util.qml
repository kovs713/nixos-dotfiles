pragma Singleton

import QtQml
import Quickshell

// Util
//
// The three things services kept rewriting for themselves, none of which knows
// anything about a particular device, protocol or app.

QtObject {
    id: root

    // get(object, name, fallback)
    //
    // Read any property off a D-Bus or Quickshell object that the sender is
    // allowed to omit, answering `fallback` when it is not there. The generated
    // objects throw on an absent property rather than answering undefined, which
    // is why every read has to be wrapped.
    //
    // flag() is this with `=== true` and `false` written in; the rest of the
    // optional reads are strings and ints, and PolkitService had five of them
    // each re-deriving the try/catch.
    function get(object, name, fallback) {
        if (object === null || object === undefined)
            return fallback;

        try {
            const value = object[name];

            return value === undefined || value === null ? fallback : value;
        } catch (e) {
            return fallback;
        }
    }

    // flag(object, name)
    //
    // Read a boolean off a D-Bus or Quickshell object without caring whether the
    // property exists. The spec lets a sender omit any hint it likes, and the
    // generated objects throw on a property that is not there rather than answering
    // undefined, so every read of a hint was wrapped by hand:
    //
    //     function isTransient(n) {
    //         try {
    //             return n !== null && n !== undefined && n.transient === true;
    //         } catch (e) {
    //             return false;
    //         }
    //     }
    //
    // Six of those in NotificationServer and three in PolkitService, byte for byte.
    // A missing hint is false, and that is the only rule.
    function flag(object, name) {
        if (object === null || object === undefined)
            return false;

        try {
            return object[name] === true;
        } catch (e) {
            return false;
        }
    }

    // notify(app, icon, urgency, summary, body)
    //
    // A desktop notification from inside the shell. Two services had this as a
    // wrapper around notify-send with the same flags, and two more spelled the flags
    // out by hand, so `urgency` was a bare string at four call sites and the icon
    // name had to be a freedesktop one rather than a Nerd Font glyph.
    function notify(app, icon, urgency, summary, body) {
        const args = ["notify-send", "-a", String(app)];

        if (icon !== undefined && icon !== null && icon !== "")
            args.push("-i", String(icon));

        // "low" | "normal" | "critical". Anything else is dropped rather than
        // passed through, because notify-send exits non-zero on a bad value and the
        // notification then never appears at all.
        const level = ["low", "normal", "critical"].indexOf(String(urgency)) >= 0 ? String(urgency) : "normal";

        args.push("-u", level, String(summary), String(body === undefined ? "" : body));

        Quickshell.execDetached(args);
    }

    // restart(process, command)
    //
    // Stop a Process and start it again on the next turn of the event loop, with an
    // optional new command.
    //
    // QProcess::setProgram is a no-op while the process is running, and every
    // command here embeds its arguments -- a brightness percentage, a bluetoothctl
    // verb, a cliphist list -- so a new command needs a fresh instance rather than a
    // reassignment. The stop and the start cannot share a turn either: setting
    // running = false and then running = true synchronously asks QProcess to start
    // something it still considers running, which does nothing and prints a warning.
    //
    // That is not hypothetical. Three call sites did exactly that
    // (BrightnessService.runProbe, ShellService.refresh, ClipboardService.refresh)
    // and worked only when the process happened to be idle -- so a manual refresh
    // during a poll silently did nothing, and the poller could not be re-armed while
    // a paste was in flight. Three other sites had already worked this out and had
    // the deferral, each with a comment re-deriving why.
    function restart(process, command) {
        if (!process)
            return;

        process.running = false;

        if (command !== undefined)
            process.command = command;

        Qt.callLater(function () {
            process.running = true;
        });
    }
    }
