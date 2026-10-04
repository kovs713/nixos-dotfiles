import QtQuick

import "." as Core

// ListRow

Rectangle {
    id: root

    // A Nerd Font glyph, or an image. `iconSource` wins when both are set: the
    // launcher rows carry a desktop entry's real icon, and an Image of 20px is
    // what a 20px glyph column is sized for.
    property string icon: ""
    property string iconSource: ""

    property string title: ""
    property string subtitle: ""
    property string trailing: ""

    property color iconColor: Core.Theme.foreground
    property color trailingColor: Core.Theme.foregroundMuted

    property bool active: false
    property bool busy: false
    property bool dimmed: false

    // Right-click gives window-space coordinates for the menu
    signal activated
    signal contextRequested(real mx, real my)

    implicitHeight: root.subtitle !== "" ? Core.Theme.rowHeight : 34

    radius: Core.Theme.radiusRow

    // The hover fill, and the only half of the row's colour that animates.
    //
    // Exactly one row is under the pointer at a time, so a transition on hover
    // is a transition on one row.
    property color hoverFill: mouse.containsMouse ? Core.Theme.surfaceHover : "transparent"

    Behavior on hoverFill {
        ColorAnimation {
            duration: 110
            easing.type: Easing.OutQuint
        }
    }

    // No Behavior here, deliberately.
    //
    // `active` does not belong to one row: a keypress flips it on the row you
    // are leaving *and* the row you are entering, and animating both meant one
    // keystroke read as two rows moving and neither looked settled. The row
    // background, this icon's colour and the indicator bar below all change
    // instantly for that reason. Selection is a state, not a transition --
    // ResultsView says so where the lists that obey it are built, and
    // Clipboard.qml's row worked this out the hard way and says so at the same
    // length.
    color: root.active ? Core.Theme.surface : root.hoverFill

    opacity: root.dimmed ? 0.45 : 1.0

    Behavior on opacity {
        NumberAnimation {
            duration: Core.Theme.durFast
            easing.type: Easing.OutQuint
        }
    }

    // Active indicator bar

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        anchors.leftMargin: 3

        width: 3
        height: root.active ? parent.height * 0.5 : 0

        radius: 2

        color: Core.Theme.accent
    }

    // Leading icon

    Text {
        id: iconText

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        width: 20

        text: root.icon

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSize

        color: root.active ? Core.Theme.accent : root.iconColor

        // The spinner replaces the glyph, so it replaces the image too.
        visible: (root.icon !== "" || root.iconSource !== "") && !root.busy

        Behavior on opacity {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutQuint
            }
        }
    }

    Image {
        anchors.fill: iconText

        visible: root.iconSource !== "" && !root.busy

        source: root.iconSource

        // A 20px box rendering a 48px or 256px PNG is where the memory goes,
        // and these are rebuilt on every filter keystroke.
        sourceSize.width: 40
        sourceSize.height: 40

        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // Busy spinner (replaces the icon)

    Text {
        anchors.centerIn: iconText

        text: Core.Icons.spinner

        font.family: Core.Theme.iconFont
        font.pixelSize: Core.Theme.iconSize

        color: Core.Theme.accent

        opacity: root.busy ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuint
            }
        }

        RotationAnimator on rotation {
            running: root.busy
            loops: Animation.Infinite

            from: 0
            to: 360

            duration: 900
        }
    }

    // Title + subtitle

    Column {
        anchors.left: iconText.right
        anchors.leftMargin: 10
        anchors.right: trailingText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        spacing: 1

        Text {
            width: parent.width

            text: root.title

            elide: Text.ElideRight

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSize

            font.weight: root.active ? Font.DemiBold : Font.Medium

            color: Core.Theme.foreground
        }

        Text {
            width: parent.width

            visible: root.subtitle !== ""

            text: root.subtitle

            elide: Text.ElideRight

            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.fontSizeSmall

            color: root.active ? Core.Theme.accent : Core.Theme.foregroundMuted
        }
    }

    // Trailing badge

    Text {
        id: trailingText

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        text: root.trailing

        font.family: Core.Theme.fontFamily
        font.pixelSize: Core.Theme.fontSizeSmall

        color: root.trailingColor
    }

    // Interaction

    MouseArea {
        id: mouse

        anchors.fill: parent

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function (event) {
            if (event.button === Qt.RightButton) {
                const p = mouse.mapToItem(null, event.x, event.y);

                root.contextRequested(p.x, p.y);
                return;
            }

            root.activated();
        }
    }

    // Press feedback

    scale: mouse.pressed ? 0.97 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutQuint
        }
    }
}
