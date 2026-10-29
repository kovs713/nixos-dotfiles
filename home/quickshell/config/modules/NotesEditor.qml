import QtQuick

TextEdit {
    id: editor

    property string mode: "NORMAL"
    readonly property bool visualMode: mode === "VISUAL" || mode === "VISUAL LINE"
    property string pending: ""
    property string registerText: ""
    property bool registerLinewise: false
    property int visualAnchor: 0
    property int visualPosition: 0

    textFormat: TextEdit.PlainText
    selectByMouse: true
    inputMethodHints: mode === "INSERT" ? Qt.ImhNone : Qt.ImhNoPredictiveText
    readOnly: mode !== "INSERT"
    cursorVisible: false

    Rectangle {
        readonly property rect caret: editor.positionToRectangle(Math.min(editor.length, editor.position()))

        x: caret.x
        y: caret.y
        width: editor.mode === "INSERT" ? 2 : Math.max(8, editor.font.pixelSize * 0.6)
        height: caret.height
        visible: editor.activeFocus
        color: editor.mode === "INSERT" ? editor.color : Qt.alpha(editor.color, 0.22)
    }

    function lineStart(pos) {
        return pos <= 0 ? 0 : editor.text.lastIndexOf("\n", pos - 1) + 1;
    }

    function lineEnd(pos) {
        const end = editor.text.indexOf("\n", pos);
        return end < 0 ? editor.length : end;
    }

    function position() {
        return editor.visualMode ? editor.visualPosition : editor.cursorPosition;
    }

    function nextCharacter(pos, backwards) {
        if (backwards) {
            const code = editor.text.charCodeAt(pos - 1);
            return Math.max(0, pos - (code >= 0xdc00 && code <= 0xdfff ? 2 : 1));
        }
        return Math.min(editor.length, pos + (editor.text.codePointAt(pos) > 0xffff ? 2 : 1));
    }

    function moveTo(pos) {
        pos = Math.max(0, Math.min(editor.length, pos));
        const code = editor.text.charCodeAt(pos);
        if (code >= 0xdc00 && code <= 0xdfff)
            pos--;
        const end = editor.lineEnd(pos);
        pos = Math.min(pos, Math.max(editor.lineStart(pos), editor.nextCharacter(end, true)));
        if (editor.visualMode) {
            editor.visualPosition = pos;
            if (editor.mode === "VISUAL LINE")
                editor.select(editor.lineStart(Math.min(editor.visualAnchor, pos)), Math.min(editor.length, editor.lineEnd(Math.max(editor.visualAnchor, pos)) + 1));
            else
                editor.select(Math.min(editor.visualAnchor, pos), editor.nextCharacter(Math.max(editor.visualAnchor, pos), false));
        } else {
            editor.cursorPosition = pos;
        }
    }

    function normal() {
        const pos = editor.mode === "INSERT" ? Math.max(editor.lineStart(editor.cursorPosition), editor.nextCharacter(editor.cursorPosition, true)) : editor.position();
        editor.mode = "NORMAL";
        editor.pending = "";
        editor.deselect();
        editor.moveTo(pos);
    }

    function wordClass(pos) {
        const char = editor.text.charAt(pos);
        if (/\s/.test(char))
            return 0;
        return /[0-9_]/.test(char) || char.toLowerCase() !== char.toUpperCase() ? 1 : 2;
    }

    function wordPosition(pos, motion) {
        if (motion === "e") {
            pos = editor.nextCharacter(pos, false);
            while (pos < editor.length && editor.wordClass(pos) === 0)
                pos = editor.nextCharacter(pos, false);
            const kind = editor.wordClass(pos);
            while (pos < editor.length && editor.wordClass(pos) === kind)
                pos = editor.nextCharacter(pos, false);
            return editor.nextCharacter(pos, true);
        } else if (motion === "b") {
            pos = Math.max(0, pos - 1);
            while (pos > 0 && editor.wordClass(pos) === 0)
                pos--;
            const kind = editor.wordClass(pos);
            while (pos > 0 && editor.wordClass(pos - 1) === kind)
                pos--;
        } else {
            const kind = editor.wordClass(pos);
            while (pos < editor.length && editor.wordClass(pos) === kind)
                pos++;
            while (pos < editor.length && editor.wordClass(pos) === 0)
                pos++;
        }
        return pos;
    }

    function paragraphPosition(pos, backwards) {
        pos = editor.lineStart(pos);
        let skippingEmpty = editor.lineEnd(pos) === pos;
        while (true) {
            if (backwards && pos === 0)
                return 0;
            if (!backwards && editor.lineEnd(pos) === editor.length)
                return editor.length;
            pos = backwards ? editor.lineStart(pos - 1) : editor.lineEnd(pos) + 1;
            if (editor.lineEnd(pos) !== pos)
                skippingEmpty = false;
            else if (!skippingEmpty)
                return pos;
        }
    }

    function yankOrDelete(removeText, linewise, change = false) {
        const pos = editor.position();
        let start = editor.selectionStart;
        let end = editor.selectionEnd;
        if (linewise && !editor.visualMode) {
            start = editor.lineStart(pos);
            end = Math.min(editor.length, editor.lineEnd(pos) + 1);
        }
        editor.select(start, end);
        editor.registerText = editor.selectedText;
        editor.registerLinewise = linewise;
        if (linewise && !editor.registerText.endsWith("\n"))
            editor.registerText += "\n";
        editor.copy();
        if (change && linewise && editor.selectedText.endsWith("\n"))
            end--;
        // Removing the last line also removes its preceding separator.
        if (removeText && !change && linewise && end === editor.length && start > 0 && !editor.selectedText.endsWith("\n"))
            start--;
        editor.mode = "NORMAL";
        editor.deselect();
        if (removeText)
            editor.remove(start, end);
        if (change) {
            editor.mode = "INSERT";
            editor.cursorPosition = start;
        } else {
            editor.moveTo(removeText ? start : pos);
        }
    }

    function put() {
        if (!editor.registerText)
            return;
        const pos = editor.position();
        if (editor.visualMode) {
            const start = editor.selectionStart;
            const end = editor.selectionEnd;
            editor.normal();
            editor.remove(start, end);
            editor.insert(start, editor.registerText);
            editor.moveTo(start);
        } else if (editor.registerLinewise) {
            const end = editor.lineEnd(pos);
            if (editor.length === 0) {
                editor.insert(0, editor.registerText.slice(0, -1));
                editor.moveTo(0);
            } else if (end === editor.length) {
                const text = editor.text.endsWith("\n") ? editor.registerText : editor.registerText.slice(0, -1);
                editor.insert(end, "\n" + text);
                editor.moveTo(end + 1);
            } else {
                editor.insert(end + 1, editor.registerText);
                editor.moveTo(end + 1);
            }
        } else {
            const target = Math.min(editor.lineEnd(pos), editor.nextCharacter(pos, false));
            editor.insert(target, editor.registerText);
            editor.moveTo(editor.nextCharacter(target + editor.registerText.length, true));
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            editor.normal();
            event.accepted = true;
            return;
        }
        if (editor.mode === "INSERT")
            return;

        event.accepted = true;
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) {
            editor.pending = "";
            return;
        }

        const key = event.modifiers & Qt.ShiftModifier ? event.text.toUpperCase() : event.text;
        const previous = editor.pending;
        editor.pending = "";
        const pos = editor.position();
        const start = editor.lineStart(pos);
        const end = editor.lineEnd(pos);

        if (previous === "g" && key === "g") {
            editor.moveTo(0);
        } else if (previous === "d" && key === "d") {
            editor.yankOrDelete(true, true);
        } else if (previous === "y" && key === "y") {
            editor.yankOrDelete(false, true);
        } else if (key === "h") {
            editor.moveTo(Math.max(start, editor.nextCharacter(pos, true)));
        } else if (key === "l") {
            editor.moveTo(Math.min(end, editor.nextCharacter(pos, false)));
        } else if (key === "j" || key === "k") {
            const target = key === "j" ? Math.min(editor.length, end + 1) : Math.max(0, start - 1);
            if ((key === "j" && end < editor.length) || (key === "k" && start > 0))
                editor.moveTo(Math.min(editor.lineEnd(target), editor.lineStart(target) + pos - start));
        } else if (key === "w" || key === "b" || key === "e") {
            editor.moveTo(editor.wordPosition(pos, key));
        } else if (key === "{" || key === "}") {
            editor.moveTo(editor.paragraphPosition(pos, key === "{"));
        } else if (key === "$") {
            editor.moveTo(end);
        } else if (key === "G") {
            editor.moveTo(editor.lineStart(editor.length));
        } else if (key === "g") {
            editor.pending = key;
        } else if (key === "v" || key === "V") {
            const mode = key === "V" ? "VISUAL LINE" : "VISUAL";
            if (editor.mode === mode) {
                editor.normal();
            } else {
                if (!editor.visualMode)
                    editor.visualAnchor = pos;
                editor.mode = mode;
                editor.moveTo(pos);
            }
        } else if (editor.visualMode && (key === "y" || key === "d" || key === "x" || key === "c")) {
            editor.yankOrDelete(key !== "y", editor.mode === "VISUAL LINE", key === "c");
        } else if (key === "p") {
            editor.put();
        } else if (editor.mode === "NORMAL") {
            if (key === "d" || key === "y") {
                editor.pending = key;
            } else if (key === "x") {
                if (pos < end) {
                    editor.select(pos, editor.nextCharacter(pos, false));
                    editor.yankOrDelete(true, false);
                }
            } else if (key === "i" || key === "a" || key === "o") {
                editor.mode = "INSERT";
                editor.cursorPosition = pos;
                if (key === "a")
                    editor.cursorPosition = Math.min(end, editor.nextCharacter(pos, false));
                else if (key === "o") {
                    editor.insert(end, "\n");
                    editor.cursorPosition = end + 1;
                }
            }
        }
    }
}
