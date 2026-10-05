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

    // ponytail: actions ranked on the same scale as apps, minus a penalty so
    // any app match always wins. Single list, single sort, no per-group buckets.
    readonly property int actionPenalty: 500

    function scoreRow(row, query) {
        if (query.length === 0)
            return 0;

        const name = row.name.toLowerCase();
        const hay = (row.name + " " + (row.subtitle || "")).toLowerCase();

        if (name.indexOf(query) === 0)
            return 400;
        if (Core.Fuzzy.wordPrefix(name, query))
            return 300;
        if (name.indexOf(query) >= 0)
            return 200;
        if (hay.indexOf(query) >= 0)
            return 140;
        if (Core.Fuzzy.subsequence(hay, query))
            return 60;

        return -1;
    }

    // ponytail: pure Function() eval, guarded by a charset regex so it can only
    // ever do arithmetic — no identifiers, no calls. Swap for a real parser if
    // you ever want units, variables or functions.
    function evaluate(expr) {
        const text = String(expr || "").trim();

        if (!/^[0-9eE+\-*/%().^ ]+$/.test(text))
            return null;

        try {
            const value = Function('"use strict";return (' + text.replace(/\^/g, "**") + ')')();

            if (typeof value !== "number" || !isFinite(value))
                return null;

            return String(parseFloat(value.toPrecision(12)));
        } catch (e) {
            return null;
        }
    }

    function search(rawQuery) {
        const raw = String(rawQuery || "").trim();

        if (raw.indexOf("=") === 0) {
            const expr = raw.slice(1).trim();
            const value = root.evaluate(expr);

            return [{
                "kind": "calc",
                "category": "Calc",
                "name": value === null ? "= " + expr : value,
                "subtitle": value === null ? "Invalid expression" : expr,
                "mdi": Core.Icons.terminal
            }];
        }

        const commandOnly = raw.indexOf(">") === 0;
        const query = commandOnly ? raw.slice(1).trim() : raw;
        const q = query.toLowerCase();
        const scored = [];
        let order = 0;

        function offer(row, score) {
            scored.push({ "row": row, "score": score, "index": order++ });
        }

        if (!commandOnly) {
            const reminder = {
                "kind": "reminder",
                "category": "Reminder",
                "name": "Reminder",
                "subtitle": "Set, show or clear reminders"
            };

            const r = root.scoreRow(reminder, q);
            if (r >= 0)
                offer(reminder, r - root.actionPenalty);

            const rows = root.actionRows;

            for (let i = 0; i < rows.length; i++) {
                const s = root.scoreRow(rows[i], q);
                if (s >= 0)
                    offer(rows[i], s - root.actionPenalty);
            }

            const apps = AppsService.rank(query);
            for (let i = 0; i < apps.length; i++)
                offer(root.appResult(apps[i].entry), apps[i].score);
        }

        if (query.length > 0) {
            const commands = ShellService.search(query);
            for (let i = 0; i < commands.length; i++)
                offer(commands[i], root.scoreRow(commands[i], q) - root.actionPenalty - 500);
        }

        const results = Core.Fuzzy.byScore(scored).map(function (item) {
            return item.row;
        });

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
