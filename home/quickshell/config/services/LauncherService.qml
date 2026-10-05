pragma Singleton

import QtQml

import "../core" as Core

QtObject {
    id: root

    readonly property var actionRows: [{
        "kind": "nightlight",
        "category": "Screen",
        "name": NightLightService.active ? "Night light: Off" : "Night light: On",
        "subtitle": NightLightService.active
            ? "Restore the native colour temperature"
            : "Shift the display warmer"
    }, {
        "kind": "shell",
        "category": "Screen",
        "name": "Screenshot: annotate",
        "subtitle": "Draw on the captured region",
        "mdi": Core.Icons.camera,
        "command": "shot annotate"
    }, {
        "kind": "shell",
        "category": "Screen",
        "name": "Screenshot: clipboard",
        "subtitle": "Copy the captured region, no editor",
        "mdi": Core.Icons.camera,
        "command": "shot clipboard"
    }, {
        "kind": "shell",
        "category": "Screen",
        "name": "Colour picker",
        "subtitle": "Pick a colour from the screen",
        "mdi": Core.Icons.palette,
        "command": "shot pick"
    }, {
        "kind": "shell",
        "category": "Record",
        "name": "Record: screen",
        "subtitle": "Portal picks screen or window, silent. Run again to stop",
        "mdi": Core.Icons.record,
        "command": "screenrec none"
    }, {
        "kind": "shell",
        "category": "Record",
        "name": "Record: screen with audio",
        "subtitle": "Portal picks screen or window, desktop audio. Run again to stop",
        "mdi": Core.Icons.record,
        "command": "screenrec audio"
    }, {
        "kind": "shell",
        "category": "Record",
        "name": "Record: screen with audio and mic",
        "subtitle": "Portal picks screen or window, desktop audio and microphone. Run again to stop",
        "mdi": Core.Icons.mic,
        "command": "screenrec av"
    }]

    function appResult(entry) {
        return {
            "kind": "app",
            "category": "Application",
            "name": entry.name,
            "subtitle": entry.genericName || entry.comment || "Application",
            "icon": entry.icon,
            "app": entry
        };
    }

    function matches(row, query) {
        if (query.length === 0)
            return true;

        const hay = (row.name + " " + row.subtitle).toLowerCase();

        return hay.indexOf(query) >= 0
            || Core.Fuzzy.wordPrefix(hay, query)
            || Core.Fuzzy.subsequence(hay, query);
    }

    function search(rawQuery) {
        const raw = String(rawQuery || "").trim();
        const lower = raw.toLowerCase();
        const commandOnly = raw.indexOf(">") === 0;
        const query = commandOnly ? raw.slice(1).trim() : raw;
        const results = [];

        if (!commandOnly) {
            const reminder = {
                "kind": "reminder",
                "category": "Reminder",
                "name": "Reminder",
                "subtitle": "Set, show or clear reminders"
            };

            if (root.matches(reminder, lower))
                results.push(reminder);

            const rows = root.actionRows;

            for (let i = 0; i < rows.length; i++) {
                if (root.matches(rows[i], lower))
                    results.push(rows[i]);
            }
        }

        if (!commandOnly) {
            const apps = AppsService.search(query);
            for (let i = 0; i < apps.length; i++)
                results.push(root.appResult(apps[i]));
        }

        if (query.length > 0) {
            const commands = ShellService.search(query);
            for (let i = 0; i < commands.length; i++)
                results.push(commands[i]);
        }

        if (results.length === 0 && raw.length > 0) {
            results.push({
                "kind": "fallback",
                "category": "Shell",
                "name": "Run " + query,
                "subtitle": "Fish command",
                "command": query
            });
        }

        return results;
    }

    function run(entry) {
        if (!entry)
            return;

        if (entry.kind === "app") {
            AppsService.launch(entry.app);
            return;
        }

        if (entry.kind === "nightlight") {
            NightLightService.toggle();
            return;
        }

        if (entry.kind === "shell" || entry.kind === "fallback")
            ShellService.run(entry.command);
    }
}
