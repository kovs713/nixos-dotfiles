import QtQuick

import "." as Core

Item {
    id: root

    property string icon: ""

    property string text: ""

    property bool shown: true

    implicitHeight: root.shown ? 70 : 0

    opacity: root.shown ? 1.0 : 0.0

    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutQuint
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuint
        }
    }

    Column {
        anchors.centerIn: parent

        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            visible: root.icon !== ""

            text: root.icon

            font.family: Core.Theme.iconFont
            font.pixelSize: Core.Theme.iconSizeMedium

            color: Core.Theme.foregroundFaint
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.text

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall

            color: Core.Theme.foregroundMuted
        }
    }
}
