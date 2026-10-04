pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

QtObject {
    id: root

    readonly property string notesPath: Core.Paths.shell + "/notes.txt"

    readonly property string saveDirectory: Core.Paths.home + "/Documents/notes"

    property string draft: ""

    property string savedNotice: ""

    readonly property FileView notesFile: FileView {
        path: root.notesPath

        blockLoading: true
        printErrors: false
    }

    readonly property FileView exportFile: FileView {
        blockLoading: false
        printErrors: false
    }

    readonly property Timer saveTimer: Timer {
        interval: 500
        repeat: false

        onTriggered: root.notesFile.setText(root.draft)
    }

    function edit(value) {
        root.draft = String(value === undefined || value === null ? "" : value);

        root.saveTimer.restart();
    }

    function load() {
        root.draft = String(root.notesFile.text() || "");

        return root.draft;
    }

    function exportText(value) {
        const file = root.saveDirectory + "/note-" + root.stamp() + ".txt";

        root.exportFile.path = file;
        root.exportFile.setText(String(value));

        root.savedNotice = file;

        return file;
    }

    function clearNotice() {
        root.savedNotice = "";
    }

    function stamp() {
        const d = new Date();
        const pad = function (value) {
            return ("0" + value).slice(-2);
        };

        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + "_" + pad(d.getHours()) + pad(d.getMinutes());
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.saveDirectory]);
    }
}
