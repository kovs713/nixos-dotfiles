pragma Singleton

import QtQml
import Quickshell

QtObject {
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

    function flag(object, name) {
        if (object === null || object === undefined)
            return false;

        try {
            return object[name] === true;
        } catch (e) {
            return false;
        }
    }

    function notify(app, icon, urgency, summary, body) {
        const args = ["notify-send", "-a", String(app)];

        if (icon !== undefined && icon !== null && icon !== "")
            args.push("-i", String(icon));

        const level = ["low", "normal", "critical"].indexOf(String(urgency)) >= 0 ? String(urgency) : "normal";

        args.push("-u", level, String(summary), String(body === undefined ? "" : body));

        Quickshell.execDetached(args);
    }

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
