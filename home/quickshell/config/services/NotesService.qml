pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "../core" as Core

// The scratch pad's storage.
//
// CONTEXT.md puts file IO in services/ and views in modules/. NotesPanel was the
// one place that broke it: two FileViews, a debounce timer, a mkdir spawn, a
// date stamp for the export filename and the load-into-editor dance were all in
// a PanelWindow. This is the same shape as TimerService and ReminderService --
// a FileView over ~/.config/shell, a debounce, and an explicit export -- and it
// is in the same directory as those two, which is the point.
//
// The editor's text lives here too, so the panel is a view over a string rather
// than a view that happens to own a file.

QtObject {
    id: root

    // ~/.config/shell, not XDG_STATE_HOME: that is where the timer, the
    // reminders and the night light already keep their state, and it is the
    // only one of the two something guarantees to exist. FileView.write does not
    // mkdir, so a path nothing created would fail silently.
    readonly property string notesPath: Core.Paths.shell + "/notes.txt"

    // Only ever touched by an explicit save.
    readonly property string saveDirectory: Core.Paths.home + "/Documents/notes"

    // The draft, which is NOT the file's contents.
    //
    // It was `readonly property string text: notesFile.text()`, and the
    // autosave below wrote `root.text` -- so it read the file and wrote the file,
    // and the editor's text never reached disk. The draft has to be a separate
    // value from the thing being saved, or there is nothing to save.
    property string draft: ""

    // Set for a moment after an export so the panel can say where it went.
    property string savedNotice: ""

    readonly property FileView notesFile: FileView {
        path: root.notesPath

        blockLoading: true
        printErrors: false
    }

    // Written only, never read back: the path is set at save time.
    readonly property FileView exportFile: FileView {
        blockLoading: false
        printErrors: false
    }

    // Autosave. Debounced rather than written on every keystroke, because a
    // TextArea emits textChanged per character and FileView.setText is a real
    // write.
    readonly property Timer saveTimer: Timer {
        interval: 500
        repeat: false

        onTriggered: root.notesFile.setText(root.draft)
    }

    // Called from the editor's onTextChanged. There is no "is loading" guard and
    // does not need one: the load below is synchronous, and writing back the
    // bytes that were just read is a no-op.
    function edit(value) {
        root.draft = String(value === undefined || value === null ? "" : value);

        root.saveTimer.restart();
    }

    // Adopt the file's contents. Returns them so the caller can hand them
    // straight to the editor in one go.
    function load() {
        root.draft = String(root.notesFile.text() || "");

        return root.draft;
    }

    // Export to ~/Documents/notes/note-<stamp>.txt and return the path.
    function exportText(value) {
        const file = root.saveDirectory + "/note-" + root.stamp() + ".txt";

        root.exportFile.path = file;
        root.exportFile.setText(String(value));

        root.savedNotice = file;

        return file;
    }

    // Called when the panel's "Saved ..." line has had its moment.
    function clearNotice() {
        root.savedNotice = "";
    }

    // YYYY-MM-DD_HHMM, local time. A filename, so it has to sort and has to be
    // unambiguous; the date and the time are separated by an underscore because
    // a dash would run the two together at a glance.
    function stamp() {
        const d = new Date();
        const pad = function (value) {
            return ("0" + value).slice(-2);
        };

        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + "_" + pad(d.getHours()) + pad(d.getMinutes());
    }

    Component.onCompleted: {
        // The export directory is the only thing here that does not already
        // exist, and FileView will not create it.
        Quickshell.execDetached(["mkdir", "-p", root.saveDirectory]);
    }
}
