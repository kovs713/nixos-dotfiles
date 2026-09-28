pragma Singleton

import QtQml

// One search surface for applications, Fish commands, and launcher actions.
//
// The built-in rows are built first so they outrank the Fish block, which comes
// last on purpose: `complete -C ""` matches nearly every word, so a command
// result would otherwise sit above the two things actually worth typing.

QtObject {
    id: root

    // Only switches that would change something are offered. A row for the
    // night light already in use is a no-op that costs a keystroke to discover.
    //
    // The night light is one row, not one per temperature: the bar module is a
    // toggle, and a launcher full of temperatures would offer a choice the rest
    // of the shell deliberately does not have. The row is named after what it
    // will do, so the label reads as the action.
    //
    // The theme is not here: two variants make it a toggle, not a choice, and
    // `SUPER + SHIFT + T` is bound to it. A row per variant would be worse
    // than nothing — it would put a "rebuilds the system" subtitle back in front
    // of a switch that no longer rebuilds anything.
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

    // Rows are built first and filtered after, rather than each block deciding
    // which queries it answers to.
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
