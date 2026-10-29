import QtQuick
import QtTest
import "../config/modules" as Modules

TestCase {
    name: "NotesEditor"
    width: 420
    height: 220
    visible: true
    when: windowShown

    Modules.NotesEditor {
        id: editor
        width: 400
        height: 200

        Rectangle {
            anchors.fill: parent
            z: -1
            color: editor.color.r > 0.5 ? "#111111" : "#eeeeee"
        }
    }

    function init() {
        editor.text = "one two\nthree\nfour";
        editor.mode = "NORMAL";
        editor.pending = "";
        editor.registerText = "";
        editor.registerLinewise = false;
        editor.cursorPosition = 0;
        editor.forceActiveFocus();
    }

    function typeKeys(keys) {
        for (const key of keys)
            keyClick(key);
    }

    function test_cursorIsRendered_data() {
        return [
            {tag: "dark", foreground: "#ffffff"},
            {tag: "light", foreground: "#111111"}
        ];
    }

    function test_cursorIsRendered(data) {
        editor.text = "";
        editor.color = data.foreground;
        for (const mode of ["NORMAL", "INSERT", "VISUAL", "NORMAL"]) {
            editor.mode = mode;
            waitForRendering(editor);
            const image = grabImage(editor);
            const y = Math.floor(editor.cursorRectangle.height / 2);
            const pixel = image.pixel(1, y);
            const background = image.pixel(30, y);
            verify(Math.abs(pixel.r - background.r) > 0.1, "Visible cursor in " + mode);
            if (mode !== "INSERT") {
                compare(image.pixel(3, y), pixel, "Uniform block without borders");
                verify(Math.abs(pixel.r - background.r) < 0.3, "Subtle block tint");
            }
        }
    }

    function test_insertAndEscape() {
        keyClick("z");
        keyClick(Qt.Key_Backspace);
        compare(editor.text, "one two\nthree\nfour");
        keyClick("i");
        compare(editor.mode, "INSERT");
        keyClick("z");
        compare(editor.text, "zone two\nthree\nfour");
        keyClick(Qt.Key_Escape);
        compare(editor.mode, "NORMAL");
        compare(editor.cursorPosition, 0);
        keyClick("a");
        keyClick("!");
        keyClick(Qt.Key_Escape);
        compare(editor.text, "z!one two\nthree\nfour");
        keyClick("o");
        keyClick("x");
        keyClick(Qt.Key_Escape);
        compare(editor.text, "z!one two\nx\nthree\nfour");
    }

    function test_motion_data() {
        return [
            {tag: "right", keys: "ll", pos: 2},
            {tag: "left-boundary", keys: "hhh", pos: 0},
            {tag: "word", keys: "w", pos: 4},
            {tag: "word-end", keys: "e", pos: 2},
            {tag: "next-word-end", keys: "ee", pos: 6},
            {tag: "word-end-next-line", keys: "eee", pos: 12},
            {tag: "back-word", keys: "wwb", pos: 4},
            {tag: "line-end", keys: "$", pos: 6},
            {tag: "down", keys: "llj", pos: 10},
            {tag: "up", keys: "lljk", pos: 2},
            {tag: "first", keys: "Ggg", pos: 0},
            {tag: "last", keys: "G", pos: 14},
            {tag: "bottom-boundary", keys: "Gjj", pos: 14},
            {tag: "line-boundary", keys: "$lll", pos: 6}
        ];
    }

    function test_motion(data) {
        typeKeys(data.keys);
        compare(editor.cursorPosition, data.pos);
        compare(editor.text, "one two\nthree\nfour");
    }

    function test_wordsAndEmptyLines() {
        editor.text = "\nпривет, мир\n\nend";
        typeKeys("w");
        compare(editor.cursorPosition, 1);
        typeKeys("w");
        compare(editor.cursorPosition, 7);
        typeKeys("w");
        compare(editor.cursorPosition, 9);
        typeKeys("b");
        compare(editor.cursorPosition, 7);
        typeKeys("gg");
        compare(editor.cursorPosition, 0);
        typeKeys("x");
        compare(editor.text, "\nпривет, мир\n\nend");
    }

    function test_wordEnd_data() {
        return [
            {tag: "punctuation", text: "hello, world", keys: "ee", pos: 5},
            {tag: "whitespace", text: "a  \n\n мир", keys: "e", pos: 8},
            {tag: "cyrillic", text: "привет мир", keys: "e", pos: 5},
            {tag: "single-letter", text: "a b", keys: "e", pos: 2},
            {tag: "end-of-file", text: "word", keys: "eee", pos: 3},
            {tag: "empty", text: "", keys: "e", pos: 0},
            {tag: "emoji", text: "a 😀", keys: "e", pos: 2}
        ];
    }

    function test_wordEnd(data) {
        editor.text = data.text;
        editor.cursorPosition = 0;
        typeKeys(data.keys);
        compare(editor.cursorPosition, data.pos);
        compare(editor.text, data.text);
    }

    function test_visualWordEnd() {
        typeKeys("ve");
        compare(editor.selectedText, "one");
        keyClick("e");
        compare(editor.selectedText, "one two");
    }

    function test_paragraphMotion_data() {
        return [
            {tag: "next", text: "one\ntwo\n\nthree\n\nfour", keys: "}", pos: 8},
            {tag: "next-from-separator", text: "one\ntwo\n\nthree\n\nfour", keys: "}}", pos: 15},
            {tag: "previous", text: "one\ntwo\n\nthree\n\nfour", keys: "G{", pos: 15},
            {tag: "previous-from-separator", text: "one\ntwo\n\nthree\n\nfour", keys: "G{{", pos: 8},
            {tag: "skip-empty-lines", text: "one\n\n\n\ntwo\n\nend", keys: "}}", pos: 11},
            {tag: "skip-empty-lines-backwards", text: "one\n\n\n\ntwo\n\nend", keys: "G{{", pos: 6},
            {tag: "no-separator", text: "one\ntwo", keys: "}", pos: 6},
            {tag: "start-boundary", text: "one\ntwo", keys: "{{", pos: 0},
            {tag: "end-boundary", text: "one\ntwo", keys: "}}", pos: 6},
            {tag: "empty", text: "", keys: "}{", pos: 0},
            {tag: "only-empty-lines", text: "\n\n", keys: "}", pos: 2},
            {tag: "whitespace-is-not-empty", text: "one\n  \nnext\n\nend", keys: "}", pos: 12},
            {tag: "emoji-at-end", text: "one\n😀", keys: "}", pos: 4}
        ];
    }

    function test_paragraphMotion(data) {
        editor.text = data.text;
        editor.cursorPosition = 0;
        typeKeys(data.keys);
        compare(editor.cursorPosition, data.pos);
        compare(editor.text, data.text);
    }

    function test_visualParagraphMotion() {
        editor.text = "one\ntwo\n\nthree\n\nfour";
        editor.cursorPosition = 0;
        typeKeys("v}");
        compare(editor.selectedText, "one\ntwo\n\n");
        typeKeys("}");
        compare(editor.selectedText, "one\ntwo\n\nthree\n\n");
        typeKeys("{");
        compare(editor.selectedText, "one\ntwo\n\n");
        keyClick(Qt.Key_Escape);
        typeKeys("GV{");
        compare(editor.mode, "VISUAL LINE");
        compare(editor.selectedText, "\nfour");
    }

    function test_lineDeleteAndPut_data() {
        return [
            {tag: "first", text: "one\ntwo\nthree", keys: "dd", deleted: "two\nthree", pasted: "two\none\nthree"},
            {tag: "middle", text: "one\ntwo\nthree", keys: "jdd", deleted: "one\nthree", pasted: "one\nthree\ntwo"},
            {tag: "last", text: "one\ntwo", keys: "Gdd", deleted: "one", pasted: "one\ntwo"},
            {tag: "only", text: "one", keys: "dd", deleted: "", pasted: "one"},
            {tag: "empty-first", text: "\none", keys: "dd", deleted: "one", pasted: "one\n"},
            {tag: "empty-last", text: "one\n", keys: "Gdd", deleted: "one", pasted: "one\n"},
            {tag: "trailing-newline", text: "one\ntwo\n", keys: "jdd", deleted: "one\n", pasted: "one\n\ntwo\n"}
        ];
    }

    function test_lineDeleteAndPut(data) {
        editor.text = data.text;
        typeKeys(data.keys);
        compare(editor.text, data.deleted);
        keyClick("p");
        compare(editor.text, data.pasted);
    }

    function test_yankAndPut() {
        typeKeys("yyp");
        compare(editor.text, "one two\none two\nthree\nfour");
        compare(editor.cursorPosition, 8);
        typeKeys("Gyyp");
        compare(editor.text, "one two\none two\nthree\nfour\nfour");
    }

    function test_characterDeleteAndPut() {
        typeKeys("xp");
        compare(editor.text, "noe two\nthree\nfour");
        editor.text = "x";
        editor.cursorPosition = 0;
        typeKeys("xp");
        compare(editor.text, "x");
    }

    function test_visual() {
        typeKeys("vll");
        compare(editor.mode, "VISUAL");
        compare(editor.selectedText, "one");
        keyClick("y");
        compare(editor.mode, "NORMAL");
        compare(editor.registerText, "one");
        compare(editor.selectedText, "");
        typeKeys("ggvld");
        compare(editor.text, "e two\nthree\nfour");
        compare(editor.mode, "NORMAL");
        typeKeys("v");
        keyClick(Qt.Key_Escape);
        compare(editor.mode, "NORMAL");
        compare(editor.selectedText, "");
    }

    function test_visualBackwardsAndReplace() {
        typeKeys("llvhh");
        compare(editor.selectedText, "one");
        keyClick("y");
        typeKeys("wvllp");
        compare(editor.text, "one one\nthree\nfour");
        compare(editor.mode, "NORMAL");
    }

    function test_visualLineSelection() {
        typeKeys("ll");
        keyClick(Qt.Key_V, Qt.ShiftModifier);
        compare(editor.mode, "VISUAL LINE");
        compare(editor.selectedText, "one two\n");
        keyClick("j");
        compare(editor.selectedText, "one two\nthree\n");
        keyClick("k");
        compare(editor.selectedText, "one two\n");
        keyClick(Qt.Key_Escape);
        compare(editor.mode, "NORMAL");
        compare(editor.selectedText, "");
        typeKeys("GVk");
        compare(editor.selectedText, "three\nfour");
    }

    function test_visualLineToggle() {
        typeKeys("lvllV");
        compare(editor.mode, "VISUAL LINE");
        compare(editor.selectedText, "one two\n");
        keyClick("v");
        compare(editor.mode, "VISUAL");
        compare(editor.selectedText, "ne ");
        typeKeys("VV");
        compare(editor.mode, "NORMAL");
        compare(editor.selectedText, "");
    }

    function test_visualLineYankAndPut() {
        typeKeys("VjyGp");
        compare(editor.mode, "NORMAL");
        verify(editor.registerLinewise);
        compare(editor.registerText, "one two\nthree\n");
        compare(editor.text, "one two\nthree\nfour\none two\nthree");
    }

    function test_visualLineDelete_data() {
        return [
            {tag: "first-two", keys: "Vjd", text: "four"},
            {tag: "last-two", keys: "GVkx", text: "one two"},
            {tag: "all", keys: "VGd", text: ""},
            {tag: "last", keys: "GVd", text: "one two\nthree"}
        ];
    }

    function test_visualLineDelete(data) {
        typeKeys(data.keys);
        compare(editor.text, data.text);
        compare(editor.mode, "NORMAL");
        verify(editor.registerLinewise);
    }

    function test_visualLineEmpty() {
        editor.text = "\none";
        typeKeys("Vd");
        compare(editor.text, "one");
        editor.text = "";
        typeKeys("Vjd");
        compare(editor.text, "");
        compare(editor.mode, "NORMAL");
    }

    function test_changeSelection_data() {
        return [
            {tag: "characters", text: "one two\nthree", keys: "vec", result: "X two\nthree"},
            {tag: "characters-at-end", text: "one two", keys: "wv$c", result: "one X"},
            {tag: "line-first", text: "one\ntwo\nthree", keys: "Vc", result: "X\ntwo\nthree"},
            {tag: "lines-middle-last", text: "one\ntwo\nthree", keys: "jVjc", result: "one\nX"},
            {tag: "line-last-terminated", text: "one\ntwo\n", keys: "jVc", result: "one\nX\n"},
            {tag: "all-lines", text: "one\ntwo", keys: "VGc", result: "X"},
            {tag: "empty", text: "", keys: "Vc", result: "X"}
        ];
    }

    function test_changeSelection(data) {
        editor.text = data.text;
        editor.cursorPosition = 0;
        typeKeys(data.keys);
        compare(editor.mode, "INSERT");
        keyClick("X");
        compare(editor.text, data.result);
        keyClick(Qt.Key_Escape);
        compare(editor.mode, "NORMAL");
    }

    function test_pendingAndEmptyDocument() {
        typeKeys("dg");
        keyClick(Qt.Key_Escape);
        compare(editor.pending, "");
        editor.text = "";
        typeKeys("hjklwb$ggGxddp");
        compare(editor.text, "");
        compare(editor.cursorPosition, 0);
    }

    function test_emoji() {
        editor.text = "😀ab😀";
        typeKeys("l");
        compare(editor.cursorPosition, 2);
        typeKeys("hxp");
        compare(editor.text, "a😀b😀");
        typeKeys("$v");
        compare(editor.selectedText, "😀");
        keyClick("x");
        compare(editor.text, "a😀b");
    }
}
