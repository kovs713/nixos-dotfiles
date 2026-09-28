pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

// QtObject rather than Item: there is not a single visual child here, and an
// Item root bought dead implicitWidth/implicitHeight and the right to be used
// as a visual parent for something that has no business being one.
QtObject {
    id: root

    property var items: []
    property bool ready: false

    // cliphist keeps image copies as raw bytes, so there is nothing for QML to
    // load until the entry is decoded to a file. Same directory cliphist's own
    // contrib script uses, so the two share the cache.
    readonly property string thumbnailDir: Core.Paths.cache + "/cliphist/thumbnails";

    property string previewKey: ""
    property string previewSource: ""
    property int previewBust: 0

    function refresh() {
        Core.Util.restart(root.listProcess);
    }

    // Put text on the clipboard. The one place that knows how.
    //
    // Four callers had their own copy of this, and two of them reached for
    // JSON.stringify as a way of quoting text for `sh -c` -- which works by
    // accident on a label with no metacharacters and does nothing at all about
    // `$`, a backtick or a backslash. The native clipboardText is the primary
    // path; wl-copy is the fallback for a session without Wayland focus, and it
    // gets the same shellQuote the paste path uses.
    function copy(text) {
        const value = String(text === undefined || text === null ? "" : text);

        if (value === "")
            return;

        try {
            Quickshell.clipboardText = value;
            return;
        } catch (e) {
            // No clipboard owner, or the compositor refused. Fall through.
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

    function paste(item) {
        if (!item)
            return;

        const command = "printf '%s\\n' " + shellQuote(item.raw) + " | cliphist decode | wl-copy";

        Quickshell.execDetached(["sh", "-c", command]);

        Quickshell.execDetached(["sh", "-c", "sleep 0.05; wtype -M ctrl v -m ctrl"]);

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

    // Decoded-file URL per key, including the cache-bust. Reusing the exact same
    // URL string is what makes a repeat visit instant: Qt keys its pixmap cache
    // on the URL, so a fresh "?n" every time re-decoded the file and dropped the
    // image for a frame on every arrow key.
    property var previewUrls: ({})

    // The key the running decode belongs to. "" means no decode is in flight, so
    // its onExited is stale and must not overwrite the current preview.
    property string decodingKey: ""

    // Decode an image entry to the thumbnail cache. Called for the selected row
    // only -- a history is capped at max-items entries, decoding all of them on
    // every open would spawn hundreds of processes for one visible thumbnail.
    function loadPreview(item) {
        const key = item && item.image ? item.id + "." + item.ext : "";

        if (key === root.previewKey)
            return;

        root.previewKey = key;

        if (!key) {
            root.decodingKey = "";
            return;
        }

        if (root.previewUrls[key] !== undefined) {
            root.previewSource = root.previewUrls[key];
            root.decodingKey = "";
            return;
        }

        // The previous image stays on screen while this one decodes. Clearing
        // the source here meant a blank pane and a flashing placeholder icon.
        root.decodingKey = key;

        const file = shellQuote(root.thumbnailDir + "/" + key);

        // decode takes the id as an argument; on stdin it cuts at the tab, so a
        // bare id would arrive with its newline attached and fail to parse.
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

                        // cliphist lists image entries as "[[ binary data 20 KiB png 637x631 ]]"
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
                root.ready = true;
            }
        }
    }

    readonly property Process previewProcess: Process {

        // The URL is cache-busted once per key: the first load of a file that is
        // still being written fails silently, so a plain path would stay blank.
        // The busted URL is then remembered in previewUrls, so coming back to an
        // image already seen is a cache hit rather than another decode.
        onExited: {
            // Stale exit: a later selection already took over, or this one was
            // served from previewUrls without a decode at all.
            if (root.decodingKey === "")
                return;

            const key = root.decodingKey;
            root.decodingKey = "";

            const url = "file://" + root.thumbnailDir + "/" + key + "?" + root.previewBust++;

            root.previewUrls[key] = url;
            root.previewSource = url;
        }
    }

    readonly property Process watcher: Process {

        // No --type filter on purpose: cliphist stores images too, and pinning
        // this to text meant image copies never reached the history.
        command: ["sh", "-c", "wl-paste --watch cliphist store"]

        running: true

        // Restart via a timer instead of reassigning running here. The immediate
        // version was an unbounded busy loop any time wl-paste could not start at
        // all -- missing binary, or no Wayland display yet.
        onExited: root.watcherRestart.start()
    }

    // A declared property rather than a child, because QtObject has no default
    // property and this one has a sibling to sit next to.
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
