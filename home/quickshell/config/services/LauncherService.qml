pragma Singleton

import QtQml

QtObject {
    id: root

    readonly property var actionRows: [{
        "kind": "nightlight",
        "category": "Screen",
        "name": NightLightService.active ? "Night light: Off" : "Night light: On",
        "subtitle": NightLightService.active
            ? "Restore the native colour temperature"
            : "Shift the display warmer"
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

        return (row.name + " " + row.subtitle).toLowerCase().indexOf(query) >= 0;
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
