pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

QtObject {
    id: root

    property var items: []

    readonly property string thumbnailDir: Core.Paths.cache + "/cliphist/thumbnails";

    property string previewKey: ""
    property string previewSource: ""
    property string previewText: ""
    property int previewBust: 0

    function refresh() {
        Core.Util.restart(root.listProcess);
    }

    function copy(text) {
        const value = String(text === undefined || text === null ? "" : text);

        if (value === "")
            return;

        try {
            Quickshell.clipboardText = value;
            return;
        } catch (e) {
        }

        copyProc.command = ["sh", "-c", "printf %s " + shellQuote(value) + " | wl-copy"];
        copyProc.running = true;
    }

    readonly property Process copyProc: Process {
        running: false
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function promote(item) {
        if (!item)
            return;

        const command = "printf '%s\\n' " + shellQuote(item.raw) + " | cliphist decode | wl-copy";

        Quickshell.execDetached(["sh", "-c", command]);
        refresh();
    }

    function remove(item) {
        if (!item)
            return;

        const command = "printf '%s\\n' " + shellQuote(item.raw) + " | cliphist delete";

        Quickshell.execDetached(["sh", "-c", command]);

        refresh();
    }

    function clear() {
        Quickshell.execDetached(["sh", "-c", "cliphist wipe"]);

        refresh();
    }

    property var previewUrls: ({})

    property string decodingKey: ""
    property string textPreviewId: ""

    function startTextPreview() {
        if (!root.textPreviewId || textPreviewProcess.running)
            return;

        // shortcut: preview only the first 64 KiB; paginate if larger previews become necessary.
        textPreviewProcess.command = ["sh", "-c", "cliphist decode \"$1\" | head -c 65536", "clipboard-preview", root.textPreviewId];
        textPreviewProcess.running = true;
    }

    function loadPreview(item) {
        const key = item ? item.id + (item.image ? "." + item.ext : ".text") : "";

        if (key === root.previewKey)
            return;

        root.previewKey = key;
        root.previewText = "";
        root.textPreviewId = item && !item.image ? item.id : "";

        if (root.textPreviewId) {
            root.decodingKey = "";
            root.startTextPreview();
            return;
        }

        if (!key) {
            root.decodingKey = "";
            return;
        }

        if (root.previewUrls[key] !== undefined) {
            root.previewSource = root.previewUrls[key];
            root.decodingKey = "";
            return;
        }

        root.decodingKey = key;

        const file = shellQuote(root.thumbnailDir + "/" + key);

        previewProcess.command = ["sh", "-c", "mkdir -p " + shellQuote(root.thumbnailDir) + " && { [ -f " + file + " ] || cliphist decode " + shellQuote(item.id) + " >" + file + "; }"];

        Core.Util.restart(root.previewProcess);
    }

    readonly property Process listProcess: Process {

        command: ["sh", "-c", "cliphist list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                const result = [];

                if (output !== "") {
                    const lines = output.split("\n");

                    for (const line of lines) {
                        if (!line.trim())
                            continue;

                        const tab = line.indexOf("\t");
                        const text = tab >= 0 ? line.slice(tab + 1) : line;

                        const binary = text.match(/^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/);

                        result.push({
                            id: tab >= 0 ? line.slice(0, tab) : line,
                            raw: line,
                            text: text,
                            image: binary !== null,
                            ext: binary ? binary[2] : "",
                            meta: binary ? binary[2].toUpperCase() + " · " + binary[3] + "×" + binary[4] + " · " + binary[1] : ""
                        });
                    }
                }

                root.items = result;
            }
        }
    }

    readonly property Process previewProcess: Process {

        onExited: {
            if (root.decodingKey === "")
                return;

            const key = root.decodingKey;
            root.decodingKey = "";

            const url = "file://" + root.thumbnailDir + "/" + key + "?" + root.previewBust++;

            root.previewUrls[key] = url;
            root.previewSource = url;
        }
    }

    readonly property Process textPreviewProcess: Process {
        stdout: StdioCollector {
            id: textOutput
        }

        onExited: {
            const id = root.textPreviewProcess.command[4];
            if (root.previewKey === id + ".text")
                root.previewText = textOutput.text;

            if (root.textPreviewId !== id)
                Qt.callLater(root.startTextPreview);
        }
    }

    readonly property Process watcher: Process {

        command: ["sh", "-c", "wl-paste --watch cliphist store"]

        running: true

        onExited: root.watcherRestart.start()
    }

    readonly property Timer watcherRestart: Timer {
        interval: 2000
        repeat: false

        onTriggered: {
            if (!root.watcher.running)
                root.watcher.running = true;
        }
    }

    Component.onCompleted: {
        refresh();
    }
}
