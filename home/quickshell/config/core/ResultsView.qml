import QtQuick

import "." as Core

GridView {
    id: root

    property int selectedIndex: 0

    property string emptyText: ""

    property int columns: 1

    property int rowHeight: 40
    property int gap: 4

    cellWidth: root.columns > 1 ? Math.floor(root.width / root.columns) : root.width
    cellHeight: root.rowHeight + root.gap

    interactive: false

    clip: true

    boundsBehavior: Flickable.StopAtBounds

    function reveal() {
        if (root.count === 0) {
            root.contentY = 0;
            return;
        }

        root.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    onSelectedIndexChanged: Qt.callLater(reveal)

    onCountChanged: Qt.callLater(reveal)

    Text {
        anchors.centerIn: parent

        visible: root.count === 0 && root.emptyText !== ""

        text: root.emptyText

        color: Core.Theme.foregroundFaint

        font.family: Core.Theme.fontMono

        font.pixelSize: Core.Theme.fontSize
    }
}
