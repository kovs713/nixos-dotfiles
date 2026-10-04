import QtQuick

import "." as Core

Item {
    id: root

    property string text: ""

    property string trailing: ""

    property real trailingOpacity: 1.0

    implicitHeight: 16

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        text: root.text

        font.family: Core.Theme.fontFamily
        font.pixelSize: Core.Theme.fontSizeSmall
        font.weight: Font.DemiBold
        font.letterSpacing: 1

        color: Core.Theme.foregroundFaint
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        visible: root.trailing !== ""

        text: root.trailing

        opacity: root.trailingOpacity

        font.family: Core.Theme.fontFamily
        font.pixelSize: Core.Theme.fontSizeSmall
        font.weight: Font.DemiBold
        font.letterSpacing: 1

        color: Core.Theme.foregroundFaint
    }
}
