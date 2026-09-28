import QtQuick
import Quickshell.Io

import "../core" as Core
import "../services" as Services

Core.LauncherView {
    id: clipboard

    launcherId: "clipboard"

    promptIcon: Core.Icons.clipboard
    placeholder: "Search clipboard"

    headerActionIcon: Core.Icons.trash
    headerActionVisible: Services.ClipboardService.items.length > 0

    cardWidth: 820
    columns: 1

    rowHeight: 52

    contentMargins: 24

    readonly property var results: {
        const q = clipboard.query.trim().toLowerCase();

        if (q === "")
            return Services.ClipboardService.items;

        return Services.ClipboardService.items.filter(function (item) {
            return item.text.toLowerCase().includes(q);
        });
    }

    itemCount: clipboard.results.length

    readonly property var selected: clipboard.results.length > clipboard.selectedIndex ? clipboard.results[clipboard.selectedIndex] : null

    // Decoding spawns a process per image row, so loading on every selectedChanged
    // meant a fast scroll queued dozens of `cliphist decode` runs and the cursor
    // visibly trailed the list. liveSelect is LauncherView's own debounce: the
    // preview follows only once the selection has been still for liveSelectDelay.
    liveSelect: true
    liveSelectDelay: 120

    onPreviewSelection: {
        Services.ClipboardService.loadPreview(clipboard.selected);
    }

    counterText: clipboard.query.length === 0 ? clipboard.results.length + " items" : clipboard.results.length + " matches"

    property bool confirmClear: false

    onDidOpen: {
        Services.ClipboardService.refresh();
        confirmClear = false;

        // liveSelect debounces arrow keys, but the first row still needs a
        // preview, and onDidOpen is the only place that knows the list is live.
        Services.ClipboardService.loadPreview(clipboard.selected);
    }

    onDidClose: {
        confirmClear = false;
    }

    onDeleteRequested: {
        clipboard.deleteSelected();
    }

    onClearAllRequested: {
        clipboard.requestClearAll();
    }

    onHeaderActionTriggered: {
        clipboard.requestClearAll();
    }

    onAccepted: {
        if (results.length === 0)
            return;

        const item = results[selectedIndex];

        if (!item)
            return;

        Services.ClipboardService.paste(item);
        clipboard.dismiss();
    }

    function deleteSelected() {
        if (results.length === 0)
            return;

        const item = results[selectedIndex];

        if (!item)
            return;

        Services.ClipboardService.remove(item);

        selectedIndex = Math.max(0, Math.min(selectedIndex, results.length - 2));
    }

    function requestClearAll() {
        if (Services.ClipboardService.items.length === 0)
            return;

        confirmClear = true;
    }

    function clearAll() {
        Services.ClipboardService.clear();

        query = "";
        selectedIndex = 0;
        confirmClear = false;
    }

    contentComponent: Component {
        Item {
            id: content

            width: parent.width
            height: parent.height

            readonly property int previewWidth: 400

            readonly property bool previewVisible: clipboard.selected !== null && clipboard.selected.image === true

            // Both columns are fixed for the life of the card. A list width that
            // tracked the selection re-wrapped and re-elided every row on each
            // arrow key, and that is what read as the list flickering.
            Row {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 12

                spacing: 8
                Core.ResultsView {
                    id: list

                    width: content.width - 24 - content.previewWidth - 8
                    height: content.height - 24

                    model: clipboard.results
                    selectedIndex: clipboard.selectedIndex

                    rowHeight: 48

                    emptyText: clipboard.query.length > 0 ? "No clipboard matches" : "Clipboard is empty"

                    delegate: Rectangle {
                        id: row

                        required property var modelData
                        required property int index

                        readonly property bool selected: row.index === list.selectedIndex

                        width: list.cellWidth
                        height: list.rowHeight

                        radius: Core.Theme.radiusRow

                        // No animation on the selection, and no scale. Both
                        // animated the row you are leaving as well as the row you
                        // are arriving on, so a single keypress moved two rows at
                        // once and neither looked settled. Selection is a state,
                        // not a transition. See ResultsView.
                        color: row.selected ? Core.Theme.surface : "transparent"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 3

                            anchors.verticalCenter: parent.verticalCenter

                            width: 3
                            height: row.selected ? parent.height * 0.5 : 0

                            radius: 2

                            color: Core.Theme.accent
                        }

                        Rectangle {
                            id: thumbnailFrame

                            visible: row.modelData.image

                            anchors.left: parent.left
                            anchors.leftMargin: 12

                            anchors.verticalCenter: parent.verticalCenter

                            width: 38
                            height: 38

                            radius: Core.Theme.radiusSmall

                            color: Core.Theme.surfaceHover

                            // Glyph, not a thumbnail. This row's Image and the large
                            // pane's Image both pointed at previewSource, so every
                            // arrow key re-decoded the file twice and the two landed
                            // a frame apart -- the double blink. One image, one decode.
                            Text {
                                anchors.centerIn: parent

                                text: Core.Icons.image

                                color: Core.Theme.foregroundFaint

                                font.family: Core.Theme.iconFont
                                font.pixelSize: 20
                            }
                        }

                        Text {
                            anchors.left: row.modelData.image ? thumbnailFrame.right : parent.left
                            anchors.leftMargin: row.modelData.image ? 10 : 14

                            anchors.right: deleteButton.left
                            anchors.rightMargin: 8

                            anchors.verticalCenter: parent.verticalCenter

                            text: row.modelData.image ? row.modelData.meta : row.modelData.text

                            color: row.selected ? Core.Theme.foreground : Core.Theme.foregroundMuted

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.Theme.fontSize

                            elide: Text.ElideRight
                            maximumLineCount: 2
                        }

                        Text {
                            id: deleteButton

                            anchors.right: parent.right
                            anchors.rightMargin: 12

                            anchors.verticalCenter: parent.verticalCenter

                            text: "×"

                            visible: row.selected

                            color: deleteMouse.containsMouse ? Core.Theme.danger : Core.Theme.foregroundFaint

                            font.family: Core.Theme.fontFamily
                            font.pixelSize: 20

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }

                            MouseArea {
                                id: deleteMouse

                                anchors.fill: parent
                                anchors.margins: -8

                                hoverEnabled: true

                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    clipboard.deleteSelected();
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 36

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                clipboard.selectedIndex = row.index;
                                clipboard.accepted();
                            }
                        }
                    }
                }

                // Fixed box, always laid out. It used to be created and destroyed
                // with the selection, which moved the list under the cursor.
                Item {
                    width: content.previewWidth
                    height: content.height - 24

                    visible: content.previewVisible

                    Rectangle {
                        anchors.fill: parent

                        radius: Core.Theme.radiusSmall

                        color: Core.Theme.surface

                        border.width: Core.Theme.borderWidth
                        border.color: Core.Theme.borderActive
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.bottomMargin: 28

                        // Never cleared to "". Qt drops the old pixmap the moment
                        // the source changes, so a clear-then-set pair blanked the
                        // pane for a frame on every key. The pane hides instead.
                        source: Services.ClipboardService.previewSource

                        fillMode: Image.PreserveAspectFit

                        // cliphist hands over the original bytes, so a 1920x1080
                        // screenshot was decoded at full size into a 400px pane --
                        // 2 megapixels of wasted work per selection change, and
                        // with asynchronous off that work was on the GUI thread,
                        // which is why fast scrolling lagged behind the cursor.
                        // sourceSize makes the image plugin scale during decode.
                        // 2x the pane, so it stays sharp on a hidpi screen.
                        sourceSize: Qt.size(800, 600)

                        // Back on: a repeat visit is a Qt cache hit on the same
                        // URL and resolves synchronously anyway, so the async
                        // path only runs on a first visit and costs a blank
                        // frame once instead of a stalled frame every time.
                        asynchronous: true
                        cache: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8

                        text: clipboard.selected ? clipboard.selected.meta : ""

                        color: Core.Theme.foregroundFaint

                        font.family: Core.Theme.fontMono
                        font.pixelSize: Core.Theme.fontSizeSmall

                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                anchors.fill: parent

                visible: clipboard.confirmClear

                radius: Core.Theme.radiusSmall

                color: Qt.rgba(Core.Theme.background.r, Core.Theme.background.g, Core.Theme.background.b, 0.96)

                z: 100

                Column {
                    anchors.centerIn: parent

                    spacing: 12

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "Clear clipboard history?"

                        color: Core.Theme.foreground

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "All saved clipboard items will be removed."

                        color: Core.Theme.foregroundMuted

                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.Theme.fontSizeSmall
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter

                        spacing: 8

                        Rectangle {
                            width: 100
                            height: 34

                            radius: Core.Theme.radiusRow

                            color: cancelMouse.containsMouse ? Core.Theme.surfaceHover : Core.Theme.surface

                            Text {
                                anchors.centerIn: parent

                                text: "Cancel"

                                color: Core.Theme.foreground

                                font.family: Core.Theme.fontFamily
                                font.pixelSize: Core.Theme.fontSizeSmall
                            }

                            MouseArea {
                                id: cancelMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    clipboard.confirmClear = false;
                                }
                            }
                        }

                        Rectangle {
                            width: 100
                            height: 34

                            radius: Core.Theme.radiusRow

                            color: clearConfirmMouse.containsMouse ? Core.Theme.danger : Core.Theme.surface

                            Text {
                                anchors.centerIn: parent

                                text: "Clear all"

                                color: Core.Theme.foreground

                                font.family: Core.Theme.fontFamily
                                font.pixelSize: Core.Theme.fontSizeSmall
                            }

                            MouseArea {
                                id: clearConfirmMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    clipboard.clearAll();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
