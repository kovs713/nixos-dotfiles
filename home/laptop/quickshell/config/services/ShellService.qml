pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

// Fish functions and commands exposed to the launcher.

QtObject {
    id: root

    readonly property string shell: "fish"
    property var commands: []

    function refresh() {
        Core.Util.restart(scan);
    }

    function ingest(raw) {
        const lines = String(raw || "").split("\n");
        const seen = {};
        const out = [];
        let inFunctions = false;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            if (line === "__FISH_FUNCTIONS__") {
                inFunctions = true;
                continue;
            }

            if (line.trim().length === 0)
                continue;

            const tab = line.indexOf("\t");
            const name = (tab >= 0 ? line.slice(0, tab) : line).trim();
            const subtitle = tab >= 0 ? line.slice(tab + 1).trim() : "";

            if (!/^[A-Za-z0-9_.+@:/=-]+$/.test(name) || seen[name])
                continue;

            seen[name] = true;
            out.push({
                "name": name,
                "subtitle": subtitle || (inFunctions ? "Fish function" : "Shell command")
            });
        }

        out.sort(function (a, b) {
            return a.name.localeCompare(b.name);
        });

        root.commands = out;
    }

    function search(rawQuery) {
        const query = String(rawQuery || "").trim().toLowerCase();
        if (query.length === 0)
            return [];

        const scored = [];
        const all = root.commands;

        for (let i = 0; i < all.length; i++) {
            const entry = all[i];
            const name = entry.name.toLowerCase();
            const subtitle = entry.subtitle.toLowerCase();
            let score = -1;

            if (name === query)
                score = 500;
            else if (name.indexOf(query) === 0)
                score = 400;
            else if (Core.Fuzzy.wordPrefix(name, query))
                score = 300;
            else if (name.indexOf(query) >= 0)
                score = 200;
            else if (subtitle.indexOf(query) >= 0)
                score = 100;
            else if (Core.Fuzzy.subsequence(name, query))
                score = 50;

            if (score >= 0)
                scored.push({ "entry": entry, "score": score, "index": i });
        }

        return Core.Fuzzy.byScore(scored).map(function (item) {
            return {
                "kind": "shell",
                "category": "Shell",
                "name": item.entry.name,
                "subtitle": item.entry.subtitle,
                "command": item.entry.name
            };
        });
    }

    function run(command) {
        if (!command || command.length === 0)
            return;

        Quickshell.execDetached([root.shell, "-l", "-c", command]);
    }

    readonly property Process scan: Process {
        command: [
            root.shell,
            "-l",
            "-c",
            "complete -C \"\"; printf '\\n__FISH_FUNCTIONS__\\n'; functions -n"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.ingest(text)
        }
    }

    Component.onCompleted: root.refresh()
}
