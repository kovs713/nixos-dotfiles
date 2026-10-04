import QtQuick

import "." as Core

Item {
    id: root

    property string popupId: ""

    readonly property bool open: root.popupId !== "" && Core.PopupManager.isOpen(root.popupId)

    property var onPrimary: null

    property var onSecondary: null
    property var onAlternate: null

    property var onScrolled: null

    property Item popTarget: null

    function pop() {
        if (root.popTarget)
            popDelay.restart();
    }

    Rectangle {
        anchors.fill: parent

        radius: height / 2

        color: root.open ? Core.Theme.surface : (mouse.containsMouse ? Core.Theme.surfaceHover : "transparent")

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutQuint
            }
        }
    }

    SequentialAnimation {
        id: popAnim

        NumberAnimation {
            target: root.popTarget
            property: "opacity"

            to: 0.55
            duration: 90
            easing.type: Easing.OutQuint
        }

        NumberAnimation {
            target: root.popTarget
            property: "opacity"

            to: 1.0
            duration: 150
            easing.type: Easing.OutQuint
        }
    }

    Timer {
        id: popDelay

        interval: 70

        onTriggered: popAnim.restart()
    }

    MouseArea {
        id: mouse

        anchors.fill: parent

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        acceptedButtons: Qt.LeftButton
            | (root.onSecondary ? Qt.RightButton : 0)
            | (root.onAlternate ? Qt.MiddleButton : 0)

        onClicked: function (event) {
            if (event.button === Qt.MiddleButton) {
                if (root.onAlternate)
                    root.onAlternate();
                return;
            }

            if (event.button === Qt.RightButton) {
                if (root.onSecondary)
                    root.onSecondary();
                return;
            }

            if (root.onPrimary) {
                root.onPrimary();
                return;
            }

            if (root.popupId !== "")
                Core.PopupManager.toggle(root.popupId, root);
        }

        onWheel: function (event) {
            if (root.onScrolled)
                root.onScrolled(event.angleDelta.y);
        }
    }
}
