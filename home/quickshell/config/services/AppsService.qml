pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

QtObject {
    id: root

    readonly property string usagePath: Core.Paths.cache + "/shell/launcher-usage.json"

    property var usage: ({})

    readonly property FileView usageFile: FileView {
        path: root.usagePath
        blockLoading: true
        printErrors: false
    }

    function loadUsage() {
        const raw = root.usageFile.text()
        if (!raw) {
            root.usage = ({})
            return
        }

        try {
            const parsed = JSON.parse(raw)
            root.usage = (parsed && typeof parsed === "object") ? parsed : ({})
        } catch (e) {
            root.usage = ({})
        }
    }

    function bump(id) {
        if (!id || id.length === 0)
            return

        const next = ({})
        const keys = Object.keys(root.usage)

        for (let i = 0; i < keys.length; i++)
            next[keys[i]] = root.usage[keys[i]]

        next[id] = (next[id] || 0) + 1
        root.usage = next

        root.usageFile.setText(JSON.stringify(next))
    }

    readonly property var entries: {
        const source = DesktopEntries.applications && DesktopEntries.applications.values ? DesktopEntries.applications.values : []
        const out = []

        for (let i = 0; i < source.length; i++) {
            const entry = source[i]
            if (!entry)
                continue

            if (entry.noDisplay === true)
                continue

            if (!entry.name || entry.name.length === 0)
                continue

            out.push(entry)
        }

        out.sort(function (a, b) {
            const an = a.name.toLowerCase()
            const bn = b.name.toLowerCase()

            if (an < bn)
                return -1

            if (an > bn)
                return 1

            return 0
        })

        return out
    }

    function score(entry, q) {
        const name = entry.name ? entry.name.toLowerCase() : ""

        if (name.indexOf(q) === 0)
            return 400

        if (Core.Fuzzy.wordPrefix(name, q))
            return 300

        if (name.indexOf(q) !== -1)
            return 200

        const generic = entry.genericName ? entry.genericName.toLowerCase() : ""
        if (generic.length > 0 && generic.indexOf(q) !== -1)
            return 140

        const comment = entry.comment ? entry.comment.toLowerCase() : ""
        if (comment.length > 0 && comment.indexOf(q) !== -1)
            return 100

        const keywords = entry.keywords
        if (keywords) {
            for (let k = 0; k < keywords.length; k++) {
                if (String(keywords[k]).toLowerCase().indexOf(q) !== -1)
                    return 100
            }
        }

        if (Core.Fuzzy.subsequence(name, q))
            return 60

        return -1
    }

    function search(query) {
        const all = root.entries

        if (!query || query.trim().length === 0)
            return all

        const q = query.trim().toLowerCase()
        const scored = []

        for (let i = 0; i < all.length; i++) {
            const entry = all[i]
            let s = root.score(entry, q)

            if (s < 0)
                continue

            const hits = root.usage[entry.id] || 0
            s += Math.min(50, hits * 6)

            scored.push({ "entry": entry, "score": s, "index": i })
        }

        const ranked = Core.Fuzzy.byScore(scored)

        const out = []
        for (let j = 0; j < ranked.length; j++)
            out.push(ranked[j].entry)

        return out
    }

    function launch(entry) {
        if (!entry)
            return

        root.bump(entry.id)

        if (entry.runInTerminal) {
            const command = ["foot", "-e"];
            for (let i = 0; i < entry.command.length; i++)
                command.push(entry.command[i]);
            Quickshell.execDetached(command);
            return;
        }

        entry.execute()
    }

    Component.onCompleted: root.loadUsage()
}
