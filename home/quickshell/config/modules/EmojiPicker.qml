import QtQuick
import Quickshell.Io

import "../core" as Core
import "../services" as Services

Core.LauncherView {
    id: picker

    launcherId: "emoji"

    promptIcon: Core.Icons.emoji
    placeholder: "Search emoji"

    cardWidth: 560
    cellHeight: 70

    contentMargins: 24

    columns: 6

    readonly property var results: {
        const result = Services.EmojiService.search(picker.query);
        return result || [];
    }

    itemCount: picker.results.length

    counterText: picker.query.length === 0 ? picker.results.length + " emoji" : picker.results.length + " matches"

    onAccepted: {
        insertSelected();
    }

    function insertSelected() {
        if (results.length === 0)
            return;

        const item = results[selectedIndex];

        if (!item || !item.emoji)
            return;

        picker.dismiss();

        Services.ClipboardService.copy(item.emoji);
    }

    contentComponent: Component {
        Core.ResultsView {
            id: grid

            anchors.fill: parent
            anchors.margins: 12

            model: picker.results
            selectedIndex: picker.selectedIndex

            columns: picker.columns
            rowHeight: picker.cellHeight

            gap: 0

            emptyText: !Services.EmojiService.ready
                ? "Loading emoji…"
                : (picker.query.length > 0 ? "No matching emoji" : "No emoji available")

            delegate: Rectangle {
                id: cell

                required property var modelData
                required property int index

                readonly property bool selected: cell.index === grid.selectedIndex

                width: grid.cellWidth
                height: grid.rowHeight

                radius: Core.Theme.radiusRow

                color: cell.selected ? Core.Theme.surface : "transparent"

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    anchors.top: parent.top

                    anchors.topMargin: 7

                    text: cell.modelData.emoji || ""

                    font.family: Core.Theme.emojiFont

                    font.pixelSize: 28

                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.left: parent.left

                    anchors.right: parent.right

                    anchors.bottom: parent.bottom

                    anchors.bottomMargin: 6

                    horizontalAlignment: Text.AlignHCenter

                    text: cell.modelData.name || ""

                    color: cell.selected ? Core.Theme.foreground : Core.Theme.foregroundFaint

                    font.family: Core.Theme.fontFamily

                    font.pixelSize: 8

                    elide: Text.ElideRight

                    maximumLineCount: 1
                }

                MouseArea {
                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        picker.selectedIndex = cell.index;

                        picker.insertSelected();
                    }
                }
            }
        }
    }
}
