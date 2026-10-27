import QtQuick

import "." as Core

Rectangle {
    id: root

    property bool active: false
    property bool selected: false
    property int actionWidth: 0

    readonly property bool emphasized: root.active || root.selected
    readonly property bool pressed: pointer.pressed

    signal activated
    signal contextRequested(real mx, real my)

    radius: Core.Theme.radiusRow

    // Hover must leave immediately; fading it out highlights two items at once.
    color: root.selected || (!root.GridView.view && pointer.containsMouse)
        ? Core.Theme.surfaceHover
        : (root.active ? Core.Theme.surface : "transparent")

    MouseArea {
        id: pointer

        anchors.fill: parent
        anchors.rightMargin: root.actionWidth

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPositionChanged: function () {
            const view = root.GridView.view as Core.ResultsView;
            if (pointer.containsMouse && view)
                view.selectAt(root.x, root.y);
        }

        onClicked: function (event) {
            if (event.button === Qt.RightButton) {
                const p = pointer.mapToItem(null, event.x, event.y);
                root.contextRequested(p.x, p.y);
                return;
            }

            root.activated();
        }
    }
}
