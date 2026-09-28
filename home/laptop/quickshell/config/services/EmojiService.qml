pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

QtObject {
    id: root

    property var items: []
    property bool ready: false

    readonly property string emojiPath: Core.Paths.assets + "/assets/emoji.json"

    readonly property FileView emojiFile: FileView {
        path: root.emojiPath

        blockLoading: false
        printErrors: true

        onLoadedChanged: {
            if (loaded)
                root.load();
        }

        onFileChanged: {
            reload();
        }
    }

    function load() {
        if (!root.emojiFile.loaded)
            return;

        try {
            const data = JSON.parse(root.emojiFile.text());

            if (!Array.isArray(data)) {
                root.items = [];
                root.ready = false;
                return;
            }

            for (let i = 0; i < data.length; i++) {
                const item = data[i];

                if (!item)
                    continue;

                let baseText = String(item.name || "") + " " + String(item.group || "") + " " + String(item.subgroup || "");

                if (Array.isArray(item.tags)) {
                    baseText += " " + item.tags.join(" ");
                }

                item.haystack = baseText.toLowerCase();
            }

            root.items = data;
            root.ready = true;
        } catch (error) {
            console.warn("Shell Emoji: failed to parse emoji database:", error);
            root.items = [];
            root.ready = false;
        }
    }

    function search(query) {
        const source = root.items || [];
        const q = String(query || "").trim().toLowerCase();

        const cleanQ = q.startsWith(":") ? q.substring(1) : q;

        if (cleanQ === "")
            return source.slice(0, 50);

        const out = [];

        for (let i = 0; i < source.length; i++) {
            const item = source[i];

            if (!item)
                continue;

            if (item.haystack !== undefined && item.haystack.indexOf(cleanQ) !== -1) {
                out.push(item);
                continue;
            }

            if (String(item.emoji || "").indexOf(cleanQ) !== -1)
                out.push(item);
        }

        return out;
    }

    Component.onCompleted: {
        if (root.emojiFile.loaded)
            root.load();
    }
}
