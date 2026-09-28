import QtQuick

import "." as Core

// EmptyState
//
// "Nothing to show", and the animated collapse that gets the card out of the way
// when there is something to show instead.
//
// Four popups wrote this out, and the three that used it identically had drifted
// to three different heights: 56, 56, 70. A card whose empty state is two
// different heights does not resize smoothly when it goes from empty to full, so
// the number is 70 here and the drift is gone with it.
//
// The collapse is animated because the card's height is: PopupSurface sizes
// itself from its content, so an empty state that snapped would make the whole
// card jump rather than settle.
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
