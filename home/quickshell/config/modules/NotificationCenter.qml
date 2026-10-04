import QtQuick

import "../core" as Core
import "../services" as Services

// Notification center bar module (leftmost slot)

Core.BarButton {
    id: root

    implicitWidth: 30
    implicitHeight: Core.Theme.moduleHeight

    popupId: "notifications"

    readonly property var list: Services.NotificationServer.history

    readonly property int count: root.list.length

    // Do-not-disturb is shared with the panel through PopupManager.
    readonly property bool dnd: Services.NotificationServer.dnd

    popTarget: icon

    onSecondary: root.clearAll
    onAlternate: function () {
        Services.NotificationServer.dnd = !Services.NotificationServer.dnd;
    }

    Text {
        id: icon

        anchors.centerIn: parent

        // Resolved through Core.Icons rather than inlined surrogate pairs --
        // hand-written pairs here are exactly how a bus ended up in the bar.
        text: root.dnd ? Core.Icons.bellOff : root.count > 0 ? Core.Icons.bellRing : Core.Icons.bell

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSize

        color: root.dnd ? Core.Theme.foregroundFaint : root.count > 0 ? Core.Theme.accent : Core.Theme.foreground

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuint
            }
        }

        onTextChanged: root.pop()
    }

    // Unread count badge

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right

        anchors.topMargin: 2
        anchors.rightMargin: 0

        width: Math.max(13, badgeText.implicitWidth + 6)
        height: 13

        radius: 7

        color: Core.Theme.accent

        visible: root.count > 0 && !root.dnd

        scale: (root.count > 0 && !root.dnd) ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuint
            }
        }

        Text {
            id: badgeText

            anchors.centerIn: parent

            text: root.count > 9 ? "9+" : root.count

            font.family: Core.Theme.fontFamily
            font.pixelSize: 9
            font.weight: Font.DemiBold

            color: Core.Theme.accentForeground
        }
    }

    function clearAll() {
        Services.NotificationServer.clearAll();
    }
}
