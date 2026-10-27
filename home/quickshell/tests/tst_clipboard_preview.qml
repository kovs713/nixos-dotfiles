import QtQuick
import QtTest
import "../config/modules" as Modules

TestCase {
    name: "ClipboardTextPreview"
    width: 420
    height: 220
    visible: true
    when: windowShown

    Modules.ClipboardTextPreview {
        id: preview
        width: 400
        height: 180
    }

    function test_largeTextStaysInsideViewport_data() {
        return [
            { tag: "multiline", text: "Long clipboard line\n".repeat(3000) },
            { tag: "unbroken", text: "x".repeat(60000) }
        ];
    }

    function test_largeTextStaysInsideViewport(data) {
        preview.text = data.text;
        tryVerify(() => preview.contentHeight > preview.height);
        compare(preview.width, 400);
        compare(preview.height, 180);
        compare(preview.contentWidth, preview.width);
        verify(preview.clip);

        mouseWheel(preview, 100, 80, 0, -120);
        tryVerify(() => preview.contentY > 0, 1000, "Text preview must scroll");

        preview.text = "Next entry";
        compare(preview.contentY, 0, "A new entry starts at the top");
        compare(preview.height, 180);
    }

    function test_markupIsPlainText() {
        preview.text = "<b>not markup</b><img src='https://example.invalid/image'>";
        const body = preview.contentItem.children[0];
        compare(body.textFormat, Text.PlainText);
        compare(body.text, preview.text);
    }
}
